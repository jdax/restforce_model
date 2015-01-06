require "salesforce_model/version"

module SalesforceModel
  extend ActiveSupport::Concern
  extend ActiveModel::Callbacks
  include ActiveModel::Model
  include ActiveModel::Validations::Callbacks
  include ActiveModel::Dirty

  included do
    map_attributes :Id
    attr_reader :client
    define_model_callbacks :save, :update, :commit, :destroy
  end

  def persisted?
    self.Id.present?
  end

  def id
    self.Id
  end

  def picklist_values(field_name)
    ActiveSupport::Notifications.instrument('salesforce.picklist_values', :field_name => field_name) do
      Rails.cache.fetch([self.class.sf_model, 'picklist_values', field_name], expires_in: ENV['CACHE_PICKLIST_EXPIRATION_HOURS'].to_i.hours) do
        client.picklist_values(self.class.sf_model, field_name).map { |elem| OpenStruct.new(elem) }
      end
    end
  end

  def initialize(client, attributes)
    @client = client
    attributes.delete(:attributes)
    super(attributes)
    reset_changes
  end

  def assign_attributes(new_attributes)
    new_attributes.each do |attr, value|
      self.public_send("#{attr}=", value)
    end if new_attributes
  end

  alias_method :attributes=, :assign_attributes


  def attributes
    ActiveSupport::HashWithIndifferentAccess.new Hash[self.class.mapped_attributes.map { |ma| [ma.to_sym, public_send(ma)] }]
  end

  def update_attributes(new_attributes)
    assign_attributes(new_attributes)
    run_callbacks :save do
      if valid?
        client.update(self.class.sf_model, sanitize_attributes(attributes.select { |k, v| changes.include?(k) }).merge(Id: id))
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
          self.Id = client.create!(self.class.sf_model, sanitize_attributes(attributes.select { |k, v| self.class.fields_for_create.include?(k) && v.present? }))
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


  protected
  def sanitize_attributes(attributes)
    # found no need to sanitize attributes manually - it is already being done
    attributes
  end


  module ClassMethods

    def map_attributes(*args)
      options = args.extract_options!
      @mapped_attributes ||= []
      @mapped_attributes.concat args
      define_attribute_methods args
      attr_reader *args
      args.each do |arg|
        if options && options[:as] == :date
          self.class_eval("def #{arg}=(val);#{arg}_will_change! unless val == @#{arg} || (val.blank? && @#{arg}.blank?);@#{arg}=Date.parse(val) rescue nil;end")
          self.class_eval("def display_#{arg};I18n.l(self.#{arg})rescue nil;end")
        elsif options && options[:as] == :datetime
          self.class_eval("def #{arg}=(val);#{arg}_will_change! unless val == @#{arg} || (val.blank? && @#{arg}.blank?);@#{arg}=DateTime.parse(val) rescue nil;end")
          self.class_eval("def display_#{arg};I18n.l(self.#{arg})rescue nil;end")
        elsif options && options[:as] == :boolean
          self.class_eval("def #{arg}=(val);#{arg}_will_change! unless val == @#{arg}; @#{arg}= (val == true || val == 'true' || val == '1');end")
          self.class_eval("def display_#{arg};I18n.l(self.#{arg})rescue nil;end")
        else
          self.class_eval("def #{arg}=(val);#{arg}_will_change! unless val == @#{arg} || (val.blank? && @#{arg}.blank?);@#{arg}=val;end")
          self.class_eval("def display_#{arg};self.#{arg};end")
        end
      end
    end

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

    def mapped_attributes
      @mapped_attributes
    end

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
        new(client, data.symbolize_keys)
      end
    end
  end
end