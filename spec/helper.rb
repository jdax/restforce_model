require 'rspec'
require 'salesforce_model'
require 'dotenv'
require 'restforce'
require 'simplecov'
require 'coveralls'

SimpleCov.formatters = [SimpleCov::Formatter::HTMLFormatter, Coveralls::SimpleCov::Formatter]

SimpleCov.start do
  add_filter '/spec/'
  add_group 'lib', '/lib'
  minimum_coverage(75.00)
end

Dotenv.load

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

# to run tests:
# bundle exec rspec spec/salesforce_model/actions_spec.rb