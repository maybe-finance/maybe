module Monetizable
    extend ActiveSupport::Concern

    class_methods do
      def monetize(*fields)
        fields.each do |field|
          define_method("#{field}_money") do
            value = self.send(field)
            value.nil? ? nil : Money.new(value, currency || Money.default_currency)
          end
        end
      end
    end
end
