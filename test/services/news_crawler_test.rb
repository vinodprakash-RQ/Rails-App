require "test_helper"

class NewsCrawlerTest < ActiveSupport::TestCase
  test "stores an article and updates an existing URL instead of duplicating it" do
    crawler = NewsCrawler.new
    document = Nokogiri::HTML(<<~HTML)
      <html><head><meta property="og:title" content="New model"><meta property="article:published_time" content="2026-01-02T12:00:00Z"></head>
      <body><article>Article content</article></body></html>
    HTML

    parsed = crawler.send(:parse_article, document, "https://openai.com/index/new-model", "openai")
    record = NewsArticle.find_or_initialize_by(url: parsed[:url])
    record.assign_attributes(parsed)
    record.save!
    record.assign_attributes(parsed.merge(title: "Updated model"))
    record.save!

    assert_equal 1, NewsArticle.where(url: "https://openai.com/index/new-model").count
    assert_equal "Updated model", NewsArticle.find_by(url: "https://openai.com/index/new-model").title
  end

  test "continues across source failures" do
    crawler = NewsCrawler.new
    crawler.stub(:fetch, ->(_url) { raise Timeout::Error, "timed out" }) do
      result = crawler.call
      assert_equal({ "openai" => 0, "google_deepmind" => 0, "anthropic" => 0 }, result)
    end
  end

  test "uses HTML fallbacks when JSON-LD is malformed" do
    document = Nokogiri::HTML(<<~HTML)
      <html><head><script type="application/ld+json">{invalid</script><meta property="og:title" content="Fallback title"></head>
      <body><time datetime="2026-03-01T00:00:00Z"></time><main>Fallback content</main></body></html>
    HTML

    article = NewsCrawler.new.send(:parse_article, document, "https://deepmind.google/blog/fallback", "google_deepmind")
    assert_equal "Fallback title", article[:title]
    assert_equal "Fallback content", article[:content]
    assert_equal Time.zone.parse("2026-03-01T00:00:00Z"), article[:published_at]
  end
end
