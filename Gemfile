source "https://rubygems.org"

ruby file: ".ruby-version"

# Rails
gem "rails", "~> 7.2.2"

# Drivers
gem "pg", "~> 1.5"

# Deployment
gem "puma", ">= 5.0"
gem "bootsnap", require: false

# Assets
gem "importmap-rails"
gem "propshaft"
gem "tailwindcss-rails"
gem "lucide-rails", github: "maybe-finance/lucide-rails"

# Hotwire
gem "stimulus-rails"
gem "turbo-rails"

# Temporary pin to commit to fix crypto.randomUUID() errors.  Revert this when the change has been released.
gem "hotwire_combobox", github: "josefarias/hotwire_combobox", ref: "b827048a8305e1115d5f96931ba1c9750d1e59fc"

# Background Jobs
gem "good_job"

# Error logging
gem "stackprof"
gem "rack-mini-profiler"
gem "sentry-ruby"
gem "sentry-rails"
gem "logtail-rails"

# Active Storage
gem "aws-sdk-s3", "~> 1.177.0", require: false
gem "image_processing", ">= 1.2"

# Other
gem "bcrypt", "~> 3.1"
gem "jwt"
gem "faraday"
gem "faraday-retry"
gem "faraday-multipart"
gem "inline_svg"
gem "octokit"
gem "pagy"
gem "rails-settings-cached"
gem "tzinfo-data", platforms: %i[windows jruby]
gem "csv"
gem "redcarpet"
gem "stripe"
gem "intercom-rails"
gem "plaid"
gem "rotp", "~> 6.3"
gem "rqrcode", "~> 2.2"

group :development, :test do
  gem "debug", platforms: %i[mri windows]
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "i18n-tasks"
  gem "erb_lint"
  gem "dotenv-rails"
end

group :development do
  gem "hotwire-livereload"
  gem "letter_opener"
  gem "ruby-lsp-rails"
  gem "web-console"
  gem "faker"
  gem "benchmark-ips"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "mocha"
  gem "vcr"
  gem "webmock"
  gem "climate_control"
  gem "simplecov", require: false
end
