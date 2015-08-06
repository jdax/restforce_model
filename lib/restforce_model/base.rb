require 'restforce_model/attributes'
require 'restforce_model/callbacks'
require 'restforce_model/actions'
require 'restforce_model/client'
require 'restforce_model/picklists'

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