# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'salesforce_model/version'

Gem::Specification.new do |spec|
  spec.name = "salesforce_model"
  spec.version = SalesforceModel::VERSION
  spec.authors = ["Piotr Steininger"]
  spec.email = ["piotr@socialdriver.com"]
  spec.summary = %q{An ActiveModel wrapper to Restforce, an Salesfore REST API Cleint for Ruby }
  spec.description = %q{This gem allows you to create ActiveRecord-like classes and add mapped attributes/fields from salesfocre}
  spec.homepage = ""
  spec.license = "MIT"

  spec.files = `git ls-files -z`.split("\x0")
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 2.6"
  spec.add_dependency "restforce", "~> 1.5.1"
  spec.add_dependency "activesupport", "~> 4.0.0"
  spec.add_dependency "activesmodel", "~> 4.0.0"
end
