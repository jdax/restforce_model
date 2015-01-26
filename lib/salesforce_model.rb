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

  def picklist_cache_ttl_hours
    ENV['CACHE_PICKLIST_EXPIRATION_HOURS'].to_i.hours rescue 24.hours
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