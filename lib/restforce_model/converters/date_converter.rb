module RestforceModel
  module Converters
    class DateConverter
      def self.from_soql(value)
        Date.parse(value) rescue nil
      end

      def self.to_soql(value)
        value.strftime("%Y-%m-%d")
      end
    end
  end
end