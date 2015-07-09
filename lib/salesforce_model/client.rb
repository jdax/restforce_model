require 'active_support/concern'
# require 'active_support/hash_with_indifferent_access'

module RestforceModel::Client
  extend ActiveSupport::Concern

  def assign_client(client)
    @client = client unless client.nil?
    @client ||= self.class.client
  end

  module ClassMethods
    def client
      if RequestStore.exist?(RestforceModel.client_key)
        RequestStore.read(RestforceModel.client_key)
      elsif RestforceModel.singleton_client
        RestforceModel.singleton_client
      else
        raise RestforceModel::Error::MissingOrInvalidClient, "Please provide an adequate client either in RequestStore or in RestforceModel.singleton_client. Can't run without a valid client"
      end
    end
  end
end