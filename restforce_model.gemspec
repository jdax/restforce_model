# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'salesforce_model/version'

Gem::Specification.new do |spec|
  spec.name = "salesforce_model"
  spec.version = RestforceModel::VERSION
  spec.authors = ["Piotr Steininger", "Maggie Epps"]
  spec.email = ["piotr@socialdriver.com", "maggie@socialdriver.com"]
  spec.summary = %q{An ActiveModel wrapper to Restforce, an Salesfore REST API Cleint for Ruby }
  spec.description = %q{This gem allows you to create ActiveRecord-like classes and add mapped attributes/fields from salesfocre}
  spec.homepage = "https://github.com/socialdriver/salesforce_model"
  spec.license = "MIT"

  spec.files = `git ls-files -z`.split("\x0")
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake", "~> 10.4"
  spec.add_development_dependency "dotenv", "~> 1.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency 'simplecov', '~> 0.9'
  spec.add_development_dependency "coveralls", '~> 0.7'
  spec.add_dependency "restforce", "~> 1.5"
  spec.add_dependency "activesupport", "> 4.0.0", "< 4.3.0"
  spec.add_dependency "activemodel", "> 4.0.0", "< 4.3.0"
  spec.add_dependency "request_store", "~> 1.1"
end
