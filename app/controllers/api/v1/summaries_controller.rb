module Api
  module V1
    class SummariesController < ApplicationController
      before_action :authenticate_user!

      def monthly
        month = Date.strptime(params.fetch(:month), "%Y-%m")
        expenses = current_user.expenses.for_month(month)
        render json: { data: { month: month.strftime("%Y-%m"), total_amount_cents: expenses.sum(:amount_cents), currency: "USD", expense_count: expenses.count } }
      rescue Date::Error, KeyError
        render json: { error: { code: "invalid_request", message: "month must be YYYY-MM" } }, status: :bad_request
      end

      def categories
        month = Date.strptime(params.fetch(:month), "%Y-%m")
        rows = current_user.expenses.for_month(month).joins(:category).group("categories.id", "categories.name").sum(:amount_cents)
        render json: { data: { month: month.strftime("%Y-%m"), currency: "USD", breakdown: rows.map { |(id, name), total| { category_id: id, category: name, amount_cents: total } }.sort_by { |row| -row[:amount_cents] } } }
      rescue Date::Error, KeyError
        render json: { error: { code: "invalid_request", message: "month must be YYYY-MM" } }, status: :bad_request
      end
    end
  end
end
