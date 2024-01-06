source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.3"

# Use main development branch of Rails
gem "rails", github: "rails/rails", branch: "main"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Authentication
gem 'devise'
gem 'omniauth'
gem 'omniauth-rails_csrf_protection'
gem 'wicked'

# Data
gem 'plaid'
gem 'money'

# Background jobs
gem 'good_job'

# External API
gem 'faraday'
gem 'geocoder'

# AI
gem "ruby-openai"

# Content
gem 'redcarpet'

# Messaging
gem 'postmark-rails'

# Error reporting
gem "sentry-ruby"
gem "sentry-rails"

# Billing
gem "pay", "~> 6.0"
gem "stripe", "~> 9.0"

# Miscellanous
gem "country_select"
gem "currency_select"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ]
  gem 'dotenv-rails'
  #gem 'devise-tailwindcssed' # Use devise views with tailwindcss
end

group :development do
  gem "web-console"
  gem 'solargraph'
  gem "hotwire-livereload"
  gem "error_highlight", ">= 0.4.0", platforms: [:ruby]
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
end
