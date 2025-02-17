module Monetizable
  extend ActiveSupport::Concern

  class_methods do
    def monetize(*fields)
      fields.each do |field|
        define_method("#{field}_money") do
          value = self.send(field)

          return nil if value.nil? || monetizable_currency.nil?

          Money.new(value, monetizable_currency)
        end
      end
    end
  end

  private
    def monetizable_currency
      currency
    end
end
