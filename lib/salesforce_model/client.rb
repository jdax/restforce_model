require 'active_support/concern'
# require 'active_support/hash_with_indifferent_access'

module SalesforceModel::Client
  extend ActiveSupport::Concern

  def assign_client(client)
    @client = client unless client.nil?
    @client ||= self.class.client
  end

  module ClassMethods
    def client
      if RequestStore.exist?(SalesforceModel.client_key)
        RequestStore.read(SalesforceModel.client_key)
      elsif SalesforceModel.singleton_client
        SalesforceModel.singleton_client
      else
        raise "Please provide an adequate client either in RequestStore or in SalesforceModel.singleton_client. Can't run without a valid client"
      end
    end
  end
end