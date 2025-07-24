source "https://rubygems.org"

ruby file: ".ruby-version"

# Rails
gem "rails", "~> 7.2.2"

# Drivers
gem "pg", "~> 1.5"
gem "redis", "~> 5.4"

# Deployment
gem "puma", ">= 5.0"
gem "bootsnap", require: false

# Assets
gem "importmap-rails"
gem "propshaft"
gem "tailwindcss-rails"
gem "lucide-rails", github: "maybe-finance/lucide-rails"

# Hotwire + UI
gem "stimulus-rails"
gem "turbo-rails"
gem "view_component"

# https://github.com/lookbook-hq/lookbook/issues/712
# TODO: Remove max version constraint when fixed
gem "lookbook", "2.3.11"

gem "hotwire_combobox"

# Background Jobs
gem "sidekiq"
gem "sidekiq-cron"

# Monitoring
gem "vernier"
gem "rack-mini-profiler"
gem "sentry-ruby"
gem "sentry-rails"
gem "sentry-sidekiq"
gem "logtail-rails"
gem "skylight", groups: [ :production ]

# Active Storage
gem "aws-sdk-s3", "~> 1.177.0", require: false
gem "image_processing", ">= 1.2"

# Other
gem "ostruct"
gem "bcrypt", "~> 3.1"
gem "jwt"
gem "jbuilder"

# OAuth & API Security
gem "doorkeeper"
gem "rack-attack", "~> 6.6"
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
gem "rqrcode", "~> 3.0"
gem "activerecord-import"
gem "rubyzip", "~> 2.3"

# State machines
gem "aasm"
gem "after_commit_everywhere", "~> 1.0"

# AI
gem "ruby-openai"

group :development, :test do
  gem "debug", platforms: %i[mri windows]
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "i18n-tasks"
  gem "erb_lint"
  gem "dotenv-rails"
end

if ENV["BENCHMARKING_ENABLED"]
  gem "dotenv-rails", groups: [ :production ]
end

group :development do
  gem "hotwire-livereload"
  gem "letter_opener"
  gem "ruby-lsp-rails"
  gem "web-console"
  gem "faker"
  gem "benchmark-ips"
  gem "stackprof"
  gem "derailed_benchmarks"
  gem "foreman"
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
