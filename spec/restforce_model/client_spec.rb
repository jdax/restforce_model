require 'spec_helper'

describe RestforceModel do
  before :each do
    @client = double("Client")
    @other_client = double("OtherClient")
  end

  after :each do
    RestforceModel.singleton_client = nil
    RequestStore.delete(RestforceModel.client_key)
  end

  it 'will prioritize the use of client set through assign client' do
    RestforceModel.singleton_client = @other_client
    class Contact < RestforceModel::Base

    end
    object = Contact.new(RestforceModel.client_key => @other_client)
    object.assign_client @client
    expect(object.client).to eq(@client)
    expect(object.client).to_not eq(@other_client)
  end

  it 'will prioritize a client in Request Store over singleton client' do
    RestforceModel.singleton_client = @other_client
    RequestStore.write(RestforceModel.client_key, @client)
    class Contact < RestforceModel::Base

    end
    object = Contact.new
    expect(object.client).to eq(@client)
    expect(object.client).to_not eq(@other_client)
  end

  it 'will use singleton client when none assigned' do
    client = double("Client")
    RestforceModel.singleton_client = client
    class Contact < RestforceModel::Base

    end
    object = Contact.new
    expect(object.client).to eq(client)
    expect(Contact.client).to eq(client)

  end
  it 'will throw an exception if no client provided' do
    class Contact < RestforceModel::Base

    end
    expect{Contact.client}.to raise_error(RestforceModel::Error::MissingOrInvalidClient)
  end


end