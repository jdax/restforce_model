require_relative '../helper'

include SalesforceModel

describe SalesforceModel do


  before :all do
    Restforce.configure do |config|
      #config.cache = Rails.cache
      config.mashify = false
    end
    SalesforceModel.singleton_client = Restforce.new(:username => ENV['SALESFORCE_GLOBAL_USERNAME'],
                                                     :password => ENV['SALESFORCE_GLOBAL_PASSWORD'],
                                                     :security_token => ENV['SALESFORCE_GLOBAL_SECURITY_TOKEN'])
    SalesforceModel.singleton_client.authenticate!

  end
  describe 'Client' do
    describe '#assign_client' do
      SalesforceModel.assign_client SalesforceModel.singleton_client
      expect(SalesforceModel.client).eq(SalesforceModel.singleton_client)

    end
  end

end