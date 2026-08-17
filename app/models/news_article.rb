class NewsArticle < ApplicationRecord
  SOURCES = %w[openai google_deepmind anthropic].freeze

  validates :source, inclusion: { in: SOURCES }
  validates :title, :url, :content, presence: true
  validates :url, uniqueness: true
  validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }

  scope :recent, -> { order(published_at: :desc, created_at: :desc) }
end
