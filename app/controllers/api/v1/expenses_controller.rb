module Api
  module V1
    class ExpensesController < ApplicationController
      before_action :authenticate_user!
      before_action :set_expense, only: [:show, :update, :destroy]

      def index
        expenses = current_user.expenses.includes(:category)
        expenses = expenses.where(category_id: params[:category_id]) if params[:category_id].present?
        expenses = expenses.where(spent_on: Date.parse(params[:date]).all_day) if params[:date].present? && Date.parse(params[:date]).present?
        expenses = expenses.where("description ILIKE ?", "%#{sanitize_sql_like(params[:search].to_s)}%") if params[:search].present?
        expenses = expenses.order(sort_column => sort_direction)
        page = [params.fetch(:page, 1).to_i, 1].max
        per_page = [[params.fetch(:per_page, 20).to_i, 1].max, 100].min
        total = expenses.count
        expenses = expenses.offset((page - 1) * per_page).limit(per_page)
        render json: { data: expenses.map { |e| expense_json(e) }, meta: { page: page, per_page: per_page, total: total, total_pages: (total.to_f / per_page).ceil } }
      rescue Date::Error
        render json: { error: { code: "invalid_request", message: "date must be YYYY-MM-DD" } }, status: :bad_request
      end

      def show = render json: { data: expense_json(@expense) }

      def create
        expense = current_user.expenses.new(expense_params)
        return render_validation_errors(expense) unless expense.save
        render json: { data: expense_json(expense) }, status: :created
      end

      def update
        return render_validation_errors(@expense) unless @expense.update(expense_params)
        render json: { data: expense_json(@expense) }
      end

      def destroy
        @expense.destroy!
        head :no_content
      end

      private

      def set_expense
        @expense = current_user.expenses.includes(:category).find(params[:id])
      end

      def expense_params
        params.permit(:amount_cents, :description, :spent_on, :category_id, :currency)
      end

      def sort_column
        %w[spent_on amount_cents description created_at].include?(params[:sort]) ? params[:sort] : "spent_on"
      end

      def sort_direction
        params[:direction].to_s.downcase == "asc" ? :asc : :desc
      end

      def expense_json(expense)
        { id: expense.id, amount_cents: expense.amount_cents, currency: expense.currency, description: expense.description, spent_on: expense.spent_on, category: { id: expense.category.id, name: expense.category.name }, created_at: expense.created_at, updated_at: expense.updated_at }
      end

      def sanitize_sql_like(value)
        ActiveRecord::Base.sanitize_sql_like(value)
      end
    end
  end
end
