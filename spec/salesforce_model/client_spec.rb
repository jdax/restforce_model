require_relative '../helper'

include RestforceModel

describe RestforceModel do


  before :all do
    Restforce.configure do |config|
      #config.cache = Rails.cache
      config.mashify = false
    end
    RestforceModel.singleton_client = Restforce.new(:username => ENV['SALESFORCE_GLOBAL_USERNAME'],
                                                     :password => ENV['SALESFORCE_GLOBAL_PASSWORD'],
                                                     :security_token => ENV['SALESFORCE_GLOBAL_SECURITY_TOKEN'])
    RestforceModel.singleton_client.authenticate!

  end
  describe 'Client' do
    describe '#assign_client' do
      RestforceModel.assign_client RestforceModel.singleton_client
      expect(RestforceModel.client).eq(RestforceModel.singleton_client)

    end
  end

end