ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)
  fixtures :none
end

class ActionDispatch::IntegrationTest
  def json
    JSON.parse(response.body)
  end

  def auth_headers(token)
    { "Authorization" => "Bearer #{token}", "CONTENT_TYPE" => "application/json" }
  end

  def create_user(email, password = "password123")
    User.create!(email: email, password: password, password_confirmation: password)
  end
end
