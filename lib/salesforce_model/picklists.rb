require 'active_support/concern'

module RestforceModel::Picklists
  extend ActiveSupport::Concern

  def picklist_values(field, options = {})
    self.class.picklist_values(field, options)
  end

  module ClassMethods
    def picklist_values(field, options = {})
      ActiveSupport::Notifications.instrument('salesforce.picklist_values', object: self.mapped_model, field: field) do
        description = RestforceModel.cache.fetch([self.mapped_model, 'describe'], expires_in: RestforceModel.picklist_cache_ttl_hours) do
          client.describe(self.mapped_model)
        end
        PicklistValues.new(description['fields'], field, options).map { |elem| OpenStruct.new(elem) }
      end
    end
    ##
    #
    # Code borrowed directly form Restforce
    # https://github.com/ejholmes/restforce/blob/92b2a0041984d3b4b058e2b4ee337a375056b598/lib/restforce/concerns/picklists.rb
    #
    class PicklistValues < Array

      def initialize(fields, field, options = {})
        @fields, @field = fields, field
        @valid_for = options.delete(:valid_for)
        raise "#{field} is not a dependent picklist" if @valid_for && !dependent?
        replace(picklist_values)
      end

      private

      attr_reader :fields

      def picklist_values
        if valid_for?
          field['picklistValues'].select { |picklist_entry| valid? picklist_entry }
        else
          field['picklistValues']
        end
      end

      # Returns true of the given field is dependent on another field.
      def dependent?
        !!field['dependentPicklist']
      end

      def valid_for?
        !!@valid_for
      end

      def controlling_picklist
        @_controlling_picklist ||= controlling_field['picklistValues'].find { |picklist_entry| picklist_entry['value'] == @valid_for }
      end

      def index
        @_index ||= controlling_field['picklistValues'].index(controlling_picklist)
      end

      def controlling_field
        @_controlling_field ||= fields.find { |f| f['name'] == field['controllerName'] }
      end

      def field
        @_field ||= fields.find { |f| f['name'] == @field }
      end

      # Returns true if the picklist entry is valid for the controlling picklist.
      #
      # See http://www.salesforce.com/us/developer/docs/api/Content/sforce_api_calls_describesobjects_describesobjectresult.htm
      def valid?(picklist_entry)
        valid_for = picklist_entry['validFor'].ljust(16, 'A').unpack('m').first.unpack('q*')
        (valid_for[index >> 3] & (0x80 >> index % 8)) != 0
      end

    end


  end


end
