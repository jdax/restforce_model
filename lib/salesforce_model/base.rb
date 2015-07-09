require 'salesforce_model/attributes'
require 'salesforce_model/callbacks'
require 'salesforce_model/actions'
require 'salesforce_model/client'
require 'salesforce_model/picklists'
require 'active_model'
require 'active_support/concern'
require 'request_store'

module RestforceModel
  class Base
    include ActiveModel::Model
    include ActiveModel::Dirty

    include Attributes
    include Callbacks
    include Actions
    include Client
    include Picklists

    attr_accessor :client

    def initialize(attributes = {})
      assign_client(attributes.delete(RestforceModel.client_key))
      attributes.delete(:attributes)
      handle_parent_attributes(attributes)
      super(attributes)
      clear_changes_information
    end

    def self.inherited(base)
      base.map_attributes :Id
    end
  end
end