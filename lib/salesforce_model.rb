require 'salesforce_model/version'
require 'active_model'
require 'active_support'

module SalesforceModel
  extend ActiveSupport::Autoload
  autoload :Base
  # in case your application uses a per-user/per-request client, use this variable as a key to store the client using RequestStore
  mattr_accessor :client_key
  @@client_key = :restforce_client

  # in case your application uses one single client for the entire app, set this to the instance of Restforce client
  mattr_accessor :singleton_client
  @@singleton_client = nil

  # cache store. override with your own store, i.e. Rails.cache
  mattr_accessor :cache
  @@cache = ActiveSupport::Cache.lookup_store(:memory_store)

  def self.picklist_cache_ttl_hours
    ENV['CACHE_PICKLIST_EXPIRATION_HOURS'].to_i.hours rescue 24.hours
  end

  class DateConverter
    def self.from_soql(value)
      Date.parse(value) rescue nil
    end
    def self.to_soql(value)
      value.strftime("%Y-%m-%d")
    end
  end
  class DateTimeConverter
    def self.from_soql(value)
      DateTime.parse(value) rescue nil
    end
    def self.to_soql(value)
      value.strftime("%Y-%m-%dT%H:%M:%S.%L%z")
    end
  end
  class BooleanConverter
    def self.from_soql(value)
      (value == true || value == 'true' || value == '1')
    end
    def self.to_soql(value)
      value
    end
  end
  class IntegerConverter
    def self.from_soql(value)
      value.to_i rescue nil
    end
    def self.to_soql(value)
      value
    end
  end
  class MultiSelectConverter

    def self.from_soql(value)
      if value.kind_of? String
        value = value.split(';') rescue []
      end
      value
    end

    def self.to_soql(value)
      value.reject { |v| v.blank? }.join("\;") rescue ""
    end
  end

  module Error
    class RecordNotFound < ::StandardError

    end

    class MissingOrInvalidClient < ::StandardError

    end

    class UnhandledParentAttributes < ::StandardError

    end
  end

end