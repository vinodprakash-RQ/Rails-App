class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: { code: "not_found", message: "Resource not found" } }, status: :not_found
  end

  rescue_from ActionController::ParameterMissing do |error|
    render json: { error: { code: "invalid_request", message: error.message } }, status: :bad_request
  end

  private

  def authenticate_user!
    token = request.headers["Authorization"].to_s.delete_prefix("Bearer ").strip
    payload = JWT.decode(token, jwt_secret, true, algorithm: "HS256").first
    @current_user = User.find(payload.fetch("sub"))
  rescue JWT::DecodeError, KeyError, ActiveRecord::RecordNotFound
    render json: { error: { code: "unauthorized", message: "A valid bearer token is required" } }, status: :unauthorized
  end

  attr_reader :current_user

  def issue_token(user)
    JWT.encode({ sub: user.id, exp: 24.hours.from_now.to_i }, jwt_secret, "HS256")
  end

  def jwt_secret
    Rails.application.secret_key_base
  end

  def render_validation_errors(record)
    render json: { error: { code: "validation_failed", message: "Validation failed", details: record.errors.to_hash } }, status: :unprocessable_entity
  end
end
