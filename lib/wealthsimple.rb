# typed: strict
# frozen_string_literal: true

require "faraday"
require "sorbet-runtime"

# Include T::Sig directly in the module class so that it doesn't need to be extended everywhere.
class Module
  include T::Sig
end

require_relative "wealthsimple/version"
require_relative "wealthsimple/client"

module WealthSimple
end
