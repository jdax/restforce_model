module RestforceModel
  module Converters
    class BooleanConverter
      def self.from_soql(value)
        (value == true || value == 'true' || value == '1')
      end
      def self.to_soql(value)
        value
      end
    end
  end
end