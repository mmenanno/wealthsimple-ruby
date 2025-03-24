# typed: strict
# frozen_string_literal: true

require "simplecov"

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require "sorbet-runtime"
require "dotenv/load"
require "wealthsimple"
require "minitest/autorun"
require "minitest/pride"
require "active_support"
require "mocha/minitest"
require "webmock/minitest"
require "vcr"

require_relative "helpers/mocha_typed"
