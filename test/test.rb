require 'salesforce_model'
require 'dotenv'
require 'restforce'
Dotenv.load

Restforce.configure do |config|
  #config.cache = Rails.cache
  config.mashify = false
end
Restforce.log = true
SalesforceModel.singleton_client = Restforce.new(:username => ENV['SALESFORCE_GLOBAL_USERNAME'],
                                                 :password => ENV['SALESFORCE_GLOBAL_PASSWORD'],
                                                 :security_token => ENV['SALESFORCE_GLOBAL_SECURITY_TOKEN'])

SalesforceModel.singleton_client.authenticate!



class Contact < SalesforceModel::Base
  map_attributes :Name

end

#
class Employment < SalesforceModel::Base
  map_model :Employment__c
  map_attributes :Name
  map_parent_attributes :Employer, :Name => :Employer_Name
end

contact = Contact.find "003J000000qgi25", SalesforceModel.singleton_client
contact.Name

emp = Employment.find "a0cJ0000002lRXg"
emp.Name



