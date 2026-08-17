require_relative "boot"
require "rails/all"

Bundler.require(*Rails.groups)

module ExpenseTracker
  class Application < Rails::Application
    config.load_defaults 7.1
    config.api_only = true
    config.time_zone = "UTC"
    config.autoload_lib(ignore: %w(assets tasks))
  end
end
