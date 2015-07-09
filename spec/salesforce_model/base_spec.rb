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
  describe 'Base' do
    describe '#initialize' do
      it 'creates a new contact of class Base' do
        contact = Contact.new
        expect(contact).to be_a RestforceModel::Base
      end
      it 'assigns Id through argument' do
      contact = Contact.new(:Id => "01")
      expect(contact.Id).to eq("01")
      end
      it 'assigns mapped attributes through argument' do
        contact = Contact.new(:Name => "Test Name")
        expect(contact.Name).to eq("Test Name")
      end
    end
  end

end