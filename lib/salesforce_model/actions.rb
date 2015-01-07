require 'active_support/concern'
# require 'active_support/hash_with_indifferent_access'

module SalesforceModel::Actions
  extend ActiveSupport::Concern

  def update_attributes(new_attributes)
    assign_attributes(new_attributes)
    run_callbacks :save do
      if valid?
        client.update(self.class.sf_model, attributes.select { |k, v| changes.include?(k) }.merge(Id: id))
        Rails.cache.delete([self.class, id])
        Rails.cache.delete_matched("#{self.class}/query/*")
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
          self.Id = client.create!(self.class.sf_model, attributes.select { |k, v| self.class.fields_for_create.include?(k) && v.present? })
          Rails.cache.delete_matched("#{self.class}/query/*")
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
        client.destroy!(self.class.sf_model, id)
        Rails.cache.delete([self.class, id])
        Rails.cache.delete_matched("#{self.class}/query/*")
      end
    end
  end

  module ClassMethods
    def query(client, conditions = nil)
      ActiveSupport::Notifications.instrument("salesforce.query", :model => self.to_s, :conditions => conditions) do
        conditions.prepend("WHERE ") unless conditions.blank?
        results = Rails.cache.fetch([self, :query, conditions]) do
          items = client.query("SELECT #{fields_for_query} FROM #{sf_model} #{conditions}")
          items.each { |item| Rails.cache.write([self, item[:Id]], item) }
        end
        results.map { |r| new(client, r.symbolize_keys) }
      end
    end

    def display_fields
      mapped_attributes.reject { |a| a == :Id }
    end

    # def mapped_attributes
    #   @mapped_attributes
    # end

    def sf_model
      raise("Class #{self} does not implement the sf_model method")
    end

    def fields_for_query
      mapped_attributes.map(&:to_s).join(",")
    end

    def fields_for_create
      mapped_attributes.reject { |f| [:Id, :Graduate_School_Name, :Current__c].include?(f) }.map(&:to_s).join(",")
    end

    def find(client, id)
      ActiveSupport::Notifications.instrument("salesforce.find", :model => self.to_s) do
        data = Rails.cache.fetch([self, id]) do
          client.query("SELECT #{fields_for_query} FROM #{sf_model} WHERE Id = '#{id}'").first
        end
        begin
          new(client, data.symbolize_keys)
        rescue Exception => e
          raise "SalesforceModel::Exception::RecordNotFound"
        end
      end
    end
  end
end
