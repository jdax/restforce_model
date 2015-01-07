require 'salesforce_model/attributes'
require 'salesforce_model/callbacks'
require 'salesforce_model/actions'
require 'active_model'
require 'active_support/concern'
require 'request_store'

module SalesforceModel
  class Base
    include ActiveModel::Model
    include ActiveModel::Validations::Callbacks
    include ActiveModel::Dirty

    include SalesforceModel::Attributes
    include SalesforceModel::Callbacks
    include SalesforceModel::Actions

    attr_accessor :client


    def initialize(attributes = {})
      assign_client(attributes.delete(SalesforceModel.client_key))
      attributes.delete(:attributes)
      super(attributes)
      clear_changes_information
    end

    def assign_client(client)
      @client = client unless client.nil?
      @client ||= begin
        if RequestStore.exist?(SalesforceModel.client_key)
          RequestStore.read(SalesforceModel.client_key)
        elsif SalesforceModel.singleton_client
          SalesforceModel.singleton_client
        else
          raise "Please provide an adequate client either in RequestStore or in SalesforceModel.singleton_client. Can't run without a valid client"
        end
      end
    end


    def self.inherited(base)
      base.map_attributes :Id
    end
  end
end