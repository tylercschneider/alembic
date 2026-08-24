source "https://rubygems.org"

# Specify your gem's dependencies in alembic.gemspec.
gemspec

gem "puma"

gem "sqlite3"

gem "propshaft"

# The dummy app's CSS build. Host apps bring their own; the engine ships no
# compiled stylesheet.
gem "tailwindcss-rails"

# UI components for the engine views. The host app provides this at runtime;
# here it's for the dummy app and view tests.
gem "keystone_ui", github: "tylercschneider/keystone_ui"

# Drives the flow canvas in a real browser; the request tests cannot reach it.
gem "capybara"
gem "selenium-webdriver"

# Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
gem "rubocop-rails-omakase", require: false

# Start debugger with binding.b [https://github.com/ruby/debug]
# gem "debug", ">= 1.0.0"
