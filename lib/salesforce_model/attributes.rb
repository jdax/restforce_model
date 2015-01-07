require 'active_support/concern'
require 'active_support/hash_with_indifferent_access'

module SalesforceModel::Attributes
  extend ActiveSupport::Concern

  def persisted?
    self.Id.present?
  end

  def id
    self.Id
  end

  def attributes
    ActiveSupport::HashWithIndifferentAccess.new Hash[self.class.mapped_attributes.map { |ma| [ma.to_sym, public_send(ma)] }]
  end

  def assign_attributes(new_attributes)
    new_attributes.each do |attr, value|
      self.public_send("#{attr}=", value)
    end if new_attributes
  end

  alias_method :attributes=, :assign_attributes


  module ClassMethods
    def mapped_attributes
      @mapped_attributes
    end

    def map_attributes(*args)
      puts "map_attributes #{args}"
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
  end
end