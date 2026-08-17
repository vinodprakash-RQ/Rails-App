class CrawlNewsJob < ApplicationJob
  queue_as :default

  def perform
    NewsCrawler.new.call
  end
end
