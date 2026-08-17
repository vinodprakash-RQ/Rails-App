require_relative "config/environment"
run Rails.application
Rails.application.routes.default_url_options[:host] = "localhost"
