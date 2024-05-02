# frozen_string_literal: true

SimpleCov.start 'rails' do
  SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
  enable_coverage :branch
end
