module RestforceModel
  module Converters
    class DateTimeConverter
      def self.from_soql(value)
        DateTime.parse(value) rescue nil
      end
      def self.to_soql(value)
        value.strftime("%Y-%m-%dT%H:%M:%S.%L%z")
      end
    end
  end
end