require "test_helper"

class NewsArticlesTest < ActionDispatch::IntegrationTest
  setup do
    @user = create_user("news-reader@example.com")
    @token = JWT.encode({ sub: @user.id, exp: 1.hour.from_now.to_i }, Rails.application.secret_key_base, "HS256")
    NewsArticle.create!(source: "openai", title: "OpenAI update", url: "https://openai.com/index/update", content: "Details", published_at: 1.day.ago)
    NewsArticle.create!(source: "anthropic", title: "Anthropic update", url: "https://www.anthropic.com/news/update", content: "Details", published_at: 2.days.ago)
  end

  test "lists and filters collected articles" do
    get "/api/v1/news_articles", params: { source: "openai" }, headers: auth_headers(@token)
    assert_response :success
    assert_equal ["openai"], json["data"].map { |article| article["source"] }
  end

  test "rejects crawl requests without the internal crawler token" do
    CrawlNewsJob.stub(:perform_later, true) do
      post "/api/v1/news_articles/crawl", headers: auth_headers(@token).merge("X-Crawler-Token" => "wrong-token")
    end
    assert_response :unauthorized
  end

  test "queues crawling with the internal crawler token" do
    previous_token = ENV["CRAWL_TRIGGER_TOKEN"]
    ENV["CRAWL_TRIGGER_TOKEN"] = "test-crawler-token"
    CrawlNewsJob.stub(:perform_later, true) do
      post "/api/v1/news_articles/crawl", headers: auth_headers(@token).merge("X-Crawler-Token" => "test-crawler-token")
    end
    assert_response :accepted
    assert_equal "queued", json.dig("data", "status")
  ensure
    ENV["CRAWL_TRIGGER_TOKEN"] = previous_token
  end

  test "rejects invalid source filters" do
    get "/api/v1/news_articles", params: { source: "unknown" }, headers: auth_headers(@token)
    assert_response :bad_request
  end
end
