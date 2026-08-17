module Api
  module V1
    class CategoriesController < ApplicationController
      before_action :authenticate_user!

      def index
        render json: { data: Category.order(:name).map { |c| category_json(c) } }
      end

      def show
        render json: { data: category_json(Category.find(params[:id])) }
      end

      private

      def category_json(category)
        { id: category.id, name: category.name }
      end
    end
  end
end
