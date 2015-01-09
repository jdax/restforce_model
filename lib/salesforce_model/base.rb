require 'salesforce_model/attributes'
require 'salesforce_model/callbacks'
require 'salesforce_model/actions'
require 'salesforce_model/client'
require 'active_model'
require 'active_support/concern'
require 'request_store'

module SalesforceModel
  class Base
    include ActiveModel::Model
    include ActiveModel::Dirty

    include Attributes
    include Callbacks
    include Actions
    include Client

    attr_accessor :client


    def initialize(attributes = {})
      assign_client(attributes.delete(SalesforceModel.client_key))
      attributes.delete(:attributes)
      super(attributes)
      clear_changes_information
    end

    def picklist_values(field_name)
      ActiveSupport::Notifications.instrument('salesforce.picklist_values', :field_name => field_name) do
        Rails.cache.fetch([self.class.mapped_model, 'picklist_values', field_name], expires_in: SalesforceModel.picklist_cache_ttl_hours) do
          client.picklist_values(self.class.mapped_model, field_name).map { |elem| OpenStruct.new(elem) }
        end
      end
    end

    def self.inherited(base)
      base.map_attributes :Id
    end


  end
end