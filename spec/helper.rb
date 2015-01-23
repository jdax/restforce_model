require 'rspec'
require 'salesforce_model'
require 'dotenv'
require 'restforce'
require 'simplecov'
require 'coveralls'
require_relative 'spec_helper'

SimpleCov.formatters = [SimpleCov::Formatter::HTMLFormatter, Coveralls::SimpleCov::Formatter]

SimpleCov.start do
  add_filter '/spec/'
  add_group 'lib', '/lib'
  minimum_coverage(99.61)
end

Dotenv.load

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end