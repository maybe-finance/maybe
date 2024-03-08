module SetCurrency
    extend ActiveSupport::Concern

    included do
        helper_method :default_currency
    end

    private
        def default_currency
            Money.default_currency = Current.user.family.currency
        end
end
