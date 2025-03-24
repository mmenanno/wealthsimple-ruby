# typed: strict
# frozen_string_literal: true

module WealthSimple
  class Error < StandardError; end
  class AuthenticationError < Error; end
  class APIError < Error; end
end
