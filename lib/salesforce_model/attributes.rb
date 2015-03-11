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
    ActiveSupport::HashWithIndifferentAccess.new Hash[self.class.mapped_attributes.keys.map { |ma| [ma.to_sym, public_send(ma)] }]
  end

  def assign_attributes(new_attributes)
    new_attributes.each do |attr, value|
      self.public_send("#{attr}=", value)
    end if new_attributes
  end

  alias_method :attributes=, :assign_attributes

  def handle_parent_attributes(attributes)
    self.class.mapped_parent_attributes.each do |parent, fields|
      parent_hash = attributes.delete(parent.to_sym)
      unless parent_hash.blank?
        fields.each do |field, mapped_to|
          attributes[mapped_to] = parent_hash[field]
        end
      end
    end
  end


  module ClassMethods

    def map_record_type(record_type)
      @mapped_record_type = record_type.to_s
    end

    def mapped_record_type
      @mapped_record_type
    end

    def map_model(model)
      @mapped_model = model.to_s
    end

    def mapped_model
      @mapped_model ||= begin
        warn("Class #{self} does not implement the mapped_model method. Using inferred name #{self}")
        self.to_s
      end
    end

    def mapped_attributes
      @mapped_attributes ||= HashWithIndifferentAccess.new
    end

    def mapped_parent_attributes
      @parent_attributes ||= HashWithIndifferentAccess.new
    end

    def map_parent_attributes(*args)
      parent = args.shift
      @parent_attributes ||= HashWithIndifferentAccess.new
      @parent_attributes[parent] ||= HashWithIndifferentAccess.new
      args.each do |arg|
        if arg.keys.first == :Id && arg.values.first == :Id
          attr_hash = {arg.keys.first => :"#{parent.to_s}_#{arg.values.first.to_s}"}
        else
          attr_hash = arg
        end
        @parent_attributes[parent].merge! attr_hash
        attr_accessor *attr_hash.values.map(&:to_sym)
      end
      @parent_attributes
    end

    def map_attributes(*args)
      options = args.extract_options!
      data_type = options[:as] || :string
      define_attribute_methods args
      attr_reader *args

      @mapped_attributes ||= HashWithIndifferentAccess.new
      args.each do |field|
        @mapped_attributes.store(field, data_type)
        self.class_eval <<-eoruby, __FILE__, __LINE__ + 1
          def #{field}=(value)
            value = self.class.from_soql(:#{field}, value)
            #{field}_will_change! unless value == @#{field}
            @#{field} = value
          end
        eoruby
      end


      # args.each do |arg|
      #   if options[:as]
      #     case options[:as]
      #       when :multi_select
      #         self.class_eval("def #{arg}=(val);#{arg}_will_change! unless val == @#{arg} || (val.blank? && @#{arg}.blank?);@#{arg}=Date.parse(val) rescue nil;end")
      #       when :date
      #         self.class_eval("def #{arg}=(val);#{arg}_will_change! unless val == @#{arg} || (val.blank? && @#{arg}.blank?);@#{arg}=Date.parse(val) rescue nil;end")
      #       when :datetime
      #         self.class_eval("def #{arg}=(val);#{arg}_will_change! unless val == @#{arg} || (val.blank? && @#{arg}.blank?);@#{arg}=DateTime.parse(val) rescue nil;end")
      #       when :boolean
      #         self.class_eval("def #{arg}=(val);#{arg}_will_change! unless val == @#{arg}; @#{arg}= (val == true || val == 'true' || val == '1');end")
      #       when :integer
      #         self.class_eval("def #{arg}=(val);#{arg}_will_change! unless val == @#{arg} || (val.blank? && @#{arg}.blank?);@#{arg}=val.to_i rescue nil;end")
      #       else
      #         warn("Attribute option #{option[:as]} not handled")
      #         self.class_eval("def #{arg}=(val);#{arg}_will_change! unless val == @#{arg} || (val.blank? && @#{arg}.blank?);@#{arg}=val;end")
      #     end
      #   else
      #     self.class_eval("def #{arg}=(val);#{arg}_will_change! unless val == @#{arg} || (val.blank? && @#{arg}.blank?);@#{arg}=val;end")
      #   end
      # end
    end
  end
end