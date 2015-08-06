# RestforceModel

An ActiveModel wrapper to [Restforce](https://github.com/ejholmes/restforce) client. This gem provides:
 - Three options to use a Restforce client: singleton, per-user/per-request, passed in a method as reference
 - Caching as a first class citizen: relies on ActiveSupport::Cache, defaulting to MemoryCache
 - Ability to map one Salesforce object to Multiple different classes (smaller API requests)
 - Narrowing scope to a particular Record Type in Salesforce
 - Declarative field mapping
 - Declarative mapping of parent attributes (reduces number of API requests)
 - Supports all ActiveModel features:
    - Validations
    - Change Tracking (ActiveModel::Dirty)
    - Naming
    - Translations
    - Callbacks
 - more features to come...

## Installation

Add this line to your application's Gemfile:

    gem 'restforce_model', github: 'socialdriver/restforce_model'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install git@github.com:socialdriver/restforce_model.git

Set up these environment variables. For development we recommend [dotenv-rails](https://rubygems.org/gems/dotenv-rails)
```
RESTFORCE_CLIENT_ID=<YOUR_APP_CLIENT_ID>
RESTFORCE_CLIENT_SECRET=<YOUR_APP_CLIENT_SECRET>
RESTFORCE_HOST=<test.salesforce.com|login.salesforce.com>
RESTFORCE_DEBUGGING=<true|false>
RESTFORCE_API_VERSION=<API_VERSION>
```

Create an initializer in your rails app `config/initializers/restforce_model.rb`, it is important to set `mashify = false`, otherwise the caching will be throwing errors. Restforce will bundle a client into the `Mashie::Hash` objects, when `mashify = true`, which contains an I/O socket:

```ruby
require 'restforce'
Restforce.configure do |config|
  config.mashify = false
end
Restforce.log = !Rails.env.production?
```

## Client Setup Options
### Dedicated User
If you're going to use one dedicated user, add the following 2 statements to the end of  `config/initializers/restforce_model.rb`:
```ruby
RestforceModel.singleton_client = Restforce.new(
    :username => ENV['RESTFORCE_USERNAME'],
    :password => ENV['RESTFORCE_PASSWORD'],
    :security_token => ENV['RESTFORCE_SECURITY_TOKEN'],
    :api_version => ENV['RESTFORCE_API_VERSION'])
RestforceModel.singleton_client.authenticate!
```
And add the following environment variables:
```
RESTFORCE_USERNAME=<YOUR_DEDICATED_USER>
RESTFORCE_PASSWORD=<YOUR_DEDICATED_USER_PASSWORD>
RESTFORCE_SECURITY_TOKEN=<YOUR_DEDICATED_USER_SECURITY_TOKEN>
```
We recommend setting the user up in Salesforce with a permission profile, which prevents password expiration, and provides no ability to access the Salesforce backend, only the API. 
### Separate connection for each user
RestforceModel gem supports the ability to use a per-user client. The perfect example of this is when the app you're building serves Portal Users. You would set up OAuth authentication (a post about it is coming shortly). and capture the token and instance URL in the session as a Hash, which you can pass to `Resforce.new`:
```ruby
auth_hash = request.env['omniauth.auth']
...
user_hash = {
      :credentials => {
          :oauth_token => auth_hash[:credentials].delete(:token),
          :instance_url => auth_hash[:credentials].delete(:instance_url)
      }
  }
...
client = Restforce.new user_hash[:credentials]
```
### Override with a specific instance of client
RestforceModel makes is easy to persist the client througout the request cycle, so that it can be referenced, without having to pass it in method signature, by using [request_store](https://github.com/steveklabnik/request_store):
```ruby 
client = Restforce.new user_hash[:credentials]
RequestStore.write(RestforceModel.client_key, client)
```
You can change the actual `RestforceModel.client_key` value in `config/initializers/restforce_model.rb`:
```ruby 
RestforceModel.client_key = :your_client_key
#default is :restforce_client
```
RestforceModel prioritizes the Restforce client in `RequestStore`. This way you can actually have 2 clients set up: global and per user. This is useful when you need to show and restrict a user to data they can see in Salesforce, but have parts of the application that shows data from Salesforce before a user is logged in (publicly available content). For that case, RestforceModel allows you to override, which client will be used to retrieve particular data.
```ruby 
class Contact < RestforceModel::Base
    map_attributes :Name
end
Contact.find "ContactID", RestforceModel.singleton_client
```

## Usage

### Mapping a Standard Object:
```ruby
class Contact < RestforceModel::Base
  map_attributes :FirstName, :LastName, :Email, :AccountId
  map_parent_attributes :Account, :Name => :AccountName
end

Contact.find("13909023")
=> #<Contact:0x007fadc3d02618  .. @AccountId="001S000000fkeFe", @AccountName="Social Driver" ... >

```
### Mapping a Custom Object:
```ruby
class Employment < RestforceModel::Base
  map_model :Employment__c
  map_attributes :Name
  map_attributes :DateStarted__c, :DateEnded__c, as: :date
  map_parent_attributes :Employer__r, :Name => :EmployerName
end

Employment.query("Contact__c = '001S000000fkeFe'")
=> [#<Employment:... @EmployerName="Social Driver" ... >,...]

```
### Mapping an Object, with a record type:
```ruby
class Supplier < RestforceModel::Base
  map_model :Account
  map_record_type :Supplier
  map_attributes :Name
end

class Customer < RestforceModel::Base
  map_model :Account
  map_record_type :Customer
  map_attributes :Name
end
```
## Contributing

1. Fork it ( http://github.com/socialdriver/restforce_model/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
