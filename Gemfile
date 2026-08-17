source "https://rubygems.org"

# Specify your gem's dependencies in venus_media_library.gemspec.
gemspec

gem "puma"

# The dummy app uses a file-backed SQLite database. The engine itself is
# database-agnostic (it only touches Active Storage tables), so contributors
# and CI do not need a separate PostgreSQL service to run the test suite.
gem "sqlite3", "~> 2.0"

gem "propshaft"

# Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
gem "rubocop-rails-omakase", require: false

# Start debugger with binding.b [https://github.com/ruby/debug]
# gem "debug", ">= 1.0.0"

# Test framework
gem "rspec-rails", ">= 6.0", group: [ :development, :test ]
