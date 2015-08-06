module RestforceModel
  module Converters
    class IntegerConverter
      def self.from_soql(value)
        value.to_i rescue nil
      end
      def self.to_soql(value)
        value
      end
    end
  end
end