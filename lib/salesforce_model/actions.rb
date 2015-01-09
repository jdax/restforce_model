require 'active_support/concern'
require 'active_model/validations'

module SalesforceModel::Actions
  extend ActiveSupport::Concern
  include ActiveModel::Validations

  def update_attributes(new_attributes)
    assign_attributes(new_attributes)
    run_callbacks :save do
      if valid?
        client.update(self.class.mapped_model, attributes.select { |k, v| changes.include?(k) }.merge(Id: id))
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
          self.Id = client.create!(self.class.mapped_model, attributes.select { |k, v| self.class.fields_for_create.include?(k) && v.present? })
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

  module ClassMethods
    def query(conditions = nil)
      ActiveSupport::Notifications.instrument("salesforce.query", :model => self.to_s, :conditions => conditions) do
        conditions.prepend("WHERE ") unless conditions.blank?
        results = SalesforceModel.cache.fetch([self, :query, conditions]) do
          items = client.query("SELECT #{fields_for_query} FROM #{mapped_model} #{conditions}")
          items.each { |item| SalesforceModel.cache.write([self, item[:Id]], item) }
        end
        results.map { |r| new(r.symbolize_keys) }
      end
    end

    def display_fields
      mapped_attributes.reject { |a| a == :Id }
    end



    def fields_for_query
      mapped_attributes.map(&:to_s).join(",")
    end

    def fields_for_create
      mapped_attributes.reject { |f| [:Id].include?(f) }.map(&:to_s).join(",")
    end

    def find(id)
      ActiveSupport::Notifications.instrument("salesforce.find", :model => self.to_s) do
        data = SalesforceModel.cache.fetch([self, id]) do
          client.query("SELECT #{fields_for_query} FROM #{mapped_model} WHERE Id = '#{id}'").first
        end
        begin
          new(data.symbolize_keys.merge({SalesforceModel.client_key => client}))
        rescue Exception => e
          raise "SalesforceModel::Exception::RecordNotFound"
        end
      end
    end
  end
end
