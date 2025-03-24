# frozen_string_literal: true

require "simplecov_json_formatter"

SimpleCov.formatter = if ENV.fetch("CI", false)
  SimpleCov::Formatter::JSONFormatter
else
  SimpleCov::Formatter::HTMLFormatter
end

# SimpleCov.minimum_coverage(90)
SimpleCov.start do
  enable_coverage :branch
  primary_coverage :branch

  add_filter "/test/"
end
