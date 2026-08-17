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
end
