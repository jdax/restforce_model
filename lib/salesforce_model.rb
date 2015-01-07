require "salesforce_model/version"
require "salesforce_model/base"
require 'active_model'
require 'active_support/concern'

module SalesforceModel

  mattr_accessor :client_key
  @@client_key = :restforce_client

  mattr_accessor :singleton_client
  @@singleton_client = nil



  def picklist_values(field_name)
    ActiveSupport::Notifications.instrument('salesforce.picklist_values', :field_name => field_name) do
      Rails.cache.fetch([self.class.sf_model, 'picklist_values', field_name], expires_in: ENV['CACHE_PICKLIST_EXPIRATION_HOURS'].to_i.hours) do
        client.picklist_values(self.class.sf_model, field_name).map { |elem| OpenStruct.new(elem) }
      end
    end
  end
end