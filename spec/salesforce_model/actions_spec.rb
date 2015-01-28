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

    class Contact < SalesforceModel::Base
      map_attributes :Name
    end
  end
  describe '#update_attributes' do
    it 'updates attributes' do
      contact = Contact.new(:Id => "01", :Name => "Delete Name")
      contact.update_attributes(:Name => "Test Name")
      expect(contact.Name).to eq("Test Name")
    end
  end
end