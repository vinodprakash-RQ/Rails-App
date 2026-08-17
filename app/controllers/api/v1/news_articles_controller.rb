module Api
  module V1
    class NewsArticlesController < ApplicationController
      before_action :authenticate_user!
      before_action :set_article, only: :show

      def index
        if params[:source].present? && !NewsArticle::SOURCES.include?(params[:source])
          return render json: { error: { code: "invalid_request", message: "source must be one of #{NewsArticle::SOURCES.join(", ")}" } }, status: :bad_request
        end

        articles = NewsArticle.recent
        articles = articles.where(source: params[:source]) if params[:source].present?
        page = [params.fetch(:page, 1).to_i, 1].max
        per_page = [[params.fetch(:per_page, 20).to_i, 1].max, 100].min
        total = articles.count
        articles = articles.offset((page - 1) * per_page).limit(per_page)
        render json: { data: articles.map { |article| article_json(article) }, meta: { page: page, per_page: per_page, total: total, total_pages: (total.to_f / per_page).ceil } }
      end

      def show
        render json: { data: article_json(@article) }
      end

      def crawl
        CrawlNewsJob.perform_later
        render json: { data: { status: "queued" } }, status: :accepted
      end

      private

      def set_article
        @article = NewsArticle.find(params[:id])
      end

      def article_json(article)
        { id: article.id, source: article.source, title: article.title, url: article.url, published_at: article.published_at, content: article.content, created_at: article.created_at, updated_at: article.updated_at }
      end
    end
  end
end
