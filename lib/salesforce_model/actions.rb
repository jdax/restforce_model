require 'active_support/concern'
require 'active_model/validations'

module SalesforceModel::Actions
  extend ActiveSupport::Concern
  include ActiveModel::Validations

  def update_attributes(new_attributes)
    assign_attributes(new_attributes)
    run_callbacks :save do
      if valid?
        client.update!(self.class.mapped_model, attributes_for_update)
        SalesforceModel.cache.delete([self.class, id])
        SalesforceModel.cache.delete_matched("#{self.class}/query/*")
        true
      else
        false
      end
    end
  end

  def save
    run_callbacks :save do
      if valid?
        ActiveSupport::Notifications.instrument("salesforce.create", :model => self.class.to_s) do
          self.Id = client.create!(self.class.mapped_model, attributes_for_create)
          SalesforceModel.cache.delete_matched("#{self.class}/query/*")
        end
        true
      else
        false
      end
    end
  end

  def destroy
    run_callbacks :destroy do
      ActiveSupport::Notifications.instrument("salesforce.destroy", :model => self.class.to_s) do
        client.destroy!(self.class.mapped_model, id)
        SalesforceModel.cache.delete([self.class, id])
        SalesforceModel.cache.delete_matched("#{self.class}/query/*")
      end
    end
  end

  def attributes_for_create
    attributes_for_create = attributes
                                .reject { |k, v| k.to_sym == :Id }
                                .select { |k, v| self.class.mapped_attributes.has_key?(k) && v.present? }
    attributes_for_create.each { |k, v| attributes_for_create[k] = self.class.to_soql(k, v) }
  end

  def attributes_for_update
    attributes_for_update = attributes.select { |k, v| changes.include?(k) || k.to_sym == :Id }
    attributes_for_update.each { |k, v| attributes_for_update[k] = self.class.to_soql(k, v) }
  end

  private :attributes_for_create
  private :attributes_for_update

  module ClassMethods

    def to_soql(field, value)
      type = self.mapped_attributes[field]
      unless type == :string
        converter = "SalesforceModel::#{type.to_s.camelize}Converter".constantize rescue nil
        value = converter.to_soql(value) unless converter.nil?
      end
      value
    end

    def from_soql(field, value)
      type = self.mapped_attributes[field]
      unless type == :string
        converter = "SalesforceModel::#{type.to_s.camelize}Converter".constantize rescue nil
        value = converter.from_soql(value) unless converter.nil?
      end
      value
    end

    # TODO add handling of passed in client
    def query(conditions = nil)
      ActiveSupport::Notifications.instrument("salesforce.query", :model => self.to_s, :conditions => conditions) do
        conditions = prepare_conditions(conditions)
        results = SalesforceModel.cache.fetch([self, :query, conditions]) do
          items = client.query("SELECT #{fields_for_query} FROM #{mapped_model} #{conditions}")
          items.each { |item| SalesforceModel.cache.write([self, item[:Id]], item) }
        end
        results.map { |r| new(r.symbolize_keys) }
      end
    end

    alias_method :where, :query


    def prepare_conditions(conditions)
      conditions.prepend("RecordType.DeveloperName = '#{mapped_record_type}' ") unless mapped_record_type.blank?
      conditions.prepend("WHERE ") unless conditions.blank?
    end

    def display_fields
      mapped_attributes.keys.reject { |a| a == :Id }
    end


    def fields_for_query
      query_fields = mapped_attributes.keys.dup
      mapped_parent_attributes.each do |parent, fields|
        fields.each_key do |field|
          query_fields.push("#{parent}.#{field}")
        end
      end
      query_fields.map(&:to_s).join(',')
    end

    def fields_for_create
      mapped_attributes.keys.reject { |f| [:Id].include?(f) }
    end

    # Retrieve an object by `Id` using Restforce.
    #
    # It uses `#mapped_model` class method and `#query_fields` as well as the passed in `Id` to retireve a record
    #
    # raises a `SalesforceModel::Exception::RecordNotFound` if the query returns nil
    #
    def find(id, client = nil)
      client ||= self.client
      ActiveSupport::Notifications.instrument("salesforce.find", :model => self.to_s) do
        begin
          # fetch data from cache or Salesforce API
          data = SalesforceModel.cache.fetch([self, id]) do
            client.query("SELECT #{fields_for_query} FROM #{mapped_model} WHERE Id = '#{id}'").first.symbolize_keys
          end
          # instantiate the object and pass in the exact same client it was retrieved with
          new(data.merge({SalesforceModel.client_key => client}))
        rescue Exception => e
          # most likely the exception is due to calling symbolize_keys on nil
          # puts e.inspect

          raise SalesforceModel::Error::RecordNotFound.new(e), "Record with Id: #{id} cannot be found. #{e.message}"
        end
      end
    end
  end
end
