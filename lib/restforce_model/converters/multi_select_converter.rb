module RestforceModel
  module Converters
    class MultiSelectConverter
      def self.from_soql(value)
        if value.kind_of? String
          value = value.split(';') rescue []
        end
        value
      end
      def self.to_soql(value)
        value.reject { |v| v.blank? }.join("\;") rescue ""
      end
    end
  end
end