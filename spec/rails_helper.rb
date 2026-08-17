require "spec_helper"

ENV["RAILS_ENV"] ||= "test"
require_relative "dummy/config/environment"

abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "capybara/rspec"

# Load support files (factories, helpers, etc.)
Dir[File.join(__dir__, "support/**/*.rb")].sort.each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.fixture_paths = [ File.join(__dir__, "fixtures") ] if config.respond_to?(:fixture_paths)
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # Route requests at the engine so `venus_media_library_engine` helpers resolve and
  # request specs hit the mounted routes.
  config.include Rails.application.routes.url_helpers

  config.before(:suite) do
    # Clean any leftover uploaded files from previous runs.
    FileUtils.rm_rf(Rails.root.join("tmp/storage")) if Rails.root.join("tmp/storage").exist?
  end

  config.after(:suite) do
    FileUtils.rm_rf(Rails.root.join("tmp/storage")) if Rails.root.join("tmp/storage").exist?
  end

  config.before(type: :system) do
    VenusMediaLibrary.configuration.current_user = -> { Widget.first }
    VenusMediaLibrary.configuration.admin = ->(_user) { false }
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
  end
end
