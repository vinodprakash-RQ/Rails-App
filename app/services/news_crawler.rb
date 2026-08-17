require "json"
require "net/http"
require "nokogiri"
require "uri"

class NewsCrawler
  USER_AGENT = "ExpenseTrackerNewsCrawler/1.0 (+https://example.com/contact)".freeze
  MAX_ARTICLES_PER_SOURCE = 50
  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 15

  SOURCES = {
    "openai" => { index: "https://openai.com/news/", host: "openai.com", path_prefix: "/index/" },
    "google_deepmind" => { index: "https://deepmind.google/blog/", host: "deepmind.google", path_prefix: "/blog/" },
    "anthropic" => { index: "https://www.anthropic.com/news", host: "www.anthropic.com", path_prefix: "/news/" }
  }.freeze

  def call
    SOURCES.each_with_object({}) do |(source, config), results|
      results[source] = crawl_source(source, config)
    end
  end

  private

  def crawl_source(source, config)
    listing = fetch(config[:index])
    links = article_links(listing, config).first(MAX_ARTICLES_PER_SOURCE)
    stored = 0

    links.each do |url|
      article = parse_article(fetch(url), url, source)
      next unless article

      record = NewsArticle.find_or_initialize_by(url: article[:url])
      record.assign_attributes(article)
      record.save!
      stored += 1
      sleep 0.2
    rescue StandardError => error
      Rails.logger.warn("News crawler skipped #{url}: #{error.class}: #{error.message}")
    end

    stored
  rescue StandardError => error
    Rails.logger.error("News crawler failed for #{source}: #{error.class}: #{error.message}")
    0
  end

  def fetch(url)
    uri = URI.parse(url)
    raise "unsupported URL" unless %w[http https].include?(uri.scheme)

    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = USER_AGENT
    request["Accept"] = "text/html,application/xhtml+xml"
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) { |http| http.request(request) }
    raise "HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    Nokogiri::HTML(response.body)
  end

  def article_links(document, config)
    document.css("a[href]").filter_map do |link|
      uri = URI.join(config[:index], link["href"])
      next unless uri.host == config[:host] && uri.path.start_with?(config[:path_prefix])
      next if uri.path == config[:path_prefix]

      uri.fragment = nil
      uri.to_s
    rescue URI::InvalidURIError
      nil
    end.uniq
  end

  def parse_article(document, url, source)
    json_ld = document.css('script[type="application/ld+json"]').filter_map do |node|
      JSON.parse(node.text)
    rescue JSON::ParserError
      nil
    end.flat_map { |value| value.is_a?(Array) ? value : [value] }.find { |value| value.is_a?(Hash) && value["@type"].to_s.include?("Article") } || {}

    title = json_ld["headline"].presence || document.at_css('meta[property="og:title"]')&.[]("content").presence || document.at_css("h1")&.text&.squish
    published = json_ld["datePublished"].presence || document.at_css('meta[property="article:published_time"]')&.[]("content").presence || document.at_css("time")&.[]("datetime")
    content = document.at_css("article")&.text&.squish.presence || document.at_css("main")&.text&.squish.presence
    return if title.blank? || content.blank?

    { source: source, title: title.truncate(500), url: url, published_at: parse_time(published), content: content }
  end

  def parse_time(value)
    Time.zone.parse(value.to_s) if value.present?
  rescue ArgumentError
    nil
  end
end
