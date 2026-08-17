require "test_helper"

class ApiV1Test < ActionDispatch::IntegrationTest
  setup do
    @category = Category.create!(name: "Food")
    @user = create_user("owner@example.com")
    @other = create_user("other@example.com")
  end

  test "registers and logs in without exposing password" do
    post "/api/v1/auth/register", params: { email: "new@example.com", password: "password123", password_confirmation: "password123" }.to_json, headers: { "CONTENT_TYPE" => "application/json" }
    assert_response :created
    assert json.dig("data", "token").present?
    assert_nil json.dig("data", "user", "password_digest")

    post "/api/v1/auth/login", params: { email: "owner@example.com", password: "password123" }.to_json, headers: { "CONTENT_TYPE" => "application/json" }
    assert_response :success
  end

  test "requires authentication" do
    get "/api/v1/expenses"
    assert_response :unauthorized
  end

  test "rejects malformed, expired, and incorrectly signed tokens" do
    get "/api/v1/users/me", headers: auth_headers("not-a-jwt")
    assert_response :unauthorized

    expired = JWT.encode({ sub: @user.id, exp: 1.minute.ago.to_i }, Rails.application.secret_key_base, "HS256")
    get "/api/v1/users/me", headers: auth_headers(expired)
    assert_response :unauthorized

    wrong_signature = JWT.encode({ sub: @user.id, exp: 1.hour.from_now.to_i }, "wrong-secret", "HS256")
    get "/api/v1/users/me", headers: auth_headers(wrong_signature)
    assert_response :unauthorized
  end

  test "prevents IDOR and supports filters and pagination" do
    owner_token = JWT.encode({ sub: @user.id, exp: 1.hour.from_now.to_i }, Rails.application.secret_key_base, "HS256")
    expense = @user.expenses.create!(category: @category, amount_cents: 2500, description: "Coffee", spent_on: Date.new(2026, 1, 5))
    other_expense = @other.expenses.create!(category: @category, amount_cents: 9000, description: "Private", spent_on: Date.new(2026, 1, 5))

    get "/api/v1/expenses", params: { search: "coffee", month: "ignored", page: 1, per_page: 1 }, headers: auth_headers(owner_token)
    assert_response :success
    assert_equal [expense.id], json["data"].map { |item| item["id"] }
    assert_not_includes json["data"].map { |item| item["id"] }, other_expense.id

    get "/api/v1/expenses/#{other_expense.id}", headers: auth_headers(owner_token)
    assert_response :not_found
  end

  test "summarizes only the current user's month and categories" do
    token = JWT.encode({ sub: @user.id, exp: 1.hour.from_now.to_i }, Rails.application.secret_key_base, "HS256")
    @user.expenses.create!(category: @category, amount_cents: 1200, description: "Meal", spent_on: Date.new(2026, 2, 1))
    @other.expenses.create!(category: @category, amount_cents: 9999, description: "Other", spent_on: Date.new(2026, 2, 1))
    get "/api/v1/summaries/monthly", params: { month: "2026-02" }, headers: auth_headers(token)
    assert_equal 1200, json.dig("data", "total_amount_cents")
    get "/api/v1/summaries/categories", params: { month: "2026-02" }, headers: auth_headers(token)
    assert_equal 1200, json.dig("data", "breakdown", 0, "amount_cents")
  end

  test "creates updates and deletes an own expense, rejecting invalid data" do
    token = JWT.encode({ sub: @user.id, exp: 1.hour.from_now.to_i }, Rails.application.secret_key_base, "HS256")
    payload = { amount_cents: 3000, description: "Train", spent_on: "2026-03-10", category_id: @category.id }
    post "/api/v1/expenses", params: payload.to_json, headers: auth_headers(token)
    assert_response :created
    expense_id = json.dig("data", "id")

    patch "/api/v1/expenses/#{expense_id}", params: { amount_cents: 0 }.to_json, headers: auth_headers(token)
    assert_response :unprocessable_entity
    patch "/api/v1/expenses/#{expense_id}", params: { description: "Updated train" }.to_json, headers: auth_headers(token)
    assert_response :success
    assert_equal "Updated train", json.dig("data", "description")
    delete "/api/v1/expenses/#{expense_id}", headers: auth_headers(token)
    assert_response :no_content
  end

  test "rejects malformed summary month" do
    token = JWT.encode({ sub: @user.id, exp: 1.hour.from_now.to_i }, Rails.application.secret_key_base, "HS256")
    get "/api/v1/summaries/monthly", params: { month: "not-a-month" }, headers: auth_headers(token)
    assert_response :bad_request
  end
end
