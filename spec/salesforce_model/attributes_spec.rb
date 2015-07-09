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

    class Contact < RestforceModel::Base
      map_attributes :Name
    end
  end
  describe '#map_attributes' do
    it 'maps attributes' do
      Contact.map_attributes(:Employer)
      expect(Contact.mapped_attributes).to include(:Employer)
    end
  end
end