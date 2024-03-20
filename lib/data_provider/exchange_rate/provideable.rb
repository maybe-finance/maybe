module DataProvider::ExchangeRate::Provideable
    def exchange_rate(from_currency, to_currency, date)
        raise NotImplementedError
    end
end
