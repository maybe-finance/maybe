class Account::Balance::ManualAccountBalanceCalculator
    def initialize(account, options = {})
      @account = account
      @calc_start_date = [ options[:calc_start_date], @account.effective_start_date ].compact.max
    end

    def calculate
      newest_valuation = normalized_valuations.first&.dig("value")
      net_transaction_flows = normalized_transactions.sum { |t| t["amount"].to_d }
      net_transaction_flows *= -1 if @account.classification == "liability"
      start_balance = newest_valuation.present? ? newest_valuation : @account.start_balance.to_d
      current_balance = start_balance - net_transaction_flows

      if @account.foreign_currency?
        current_balance = convert_balance_to_family_currency(current_balance)
        # @daily_balances.concat(converted_balances)
      end

      current_balance
    end

    private
      def convert_balance_to_family_currency(balance)
        rate = ExchangeRate.find_rate(
          from: @account.currency,
          to: @account.family.currency,
          date: Date.current
        )

        raise "Rate for #{@account.currency} to #{@account.family.currency} on #{balance[:date]} not found" if rate.nil?
        balance * rate.rate
      end

      # For calculation, all transactions and valuations need to be normalized to the same currency (the account's primary currency)
      def normalize_entries_to_account_currency(entries, value_key)
        entries.map do |entry|
          currency = entry.currency
          date = entry.date
          value = entry.send(value_key)

          if currency != @account.currency
            rate = ExchangeRate.find_by(base_currency: currency, converted_currency: @account.currency, date: date)
            raise "Rate for #{currency} to #{@account.currency} not found" unless rate

            value *= rate.rate
            currency = @account.currency
          end

          entry.attributes.merge(value_key.to_s => value, "currency" => currency)
        end
      end

      def normalized_valuations
        # TODO: only read one
        @normalized_valuations ||= normalize_entries_to_account_currency(@account.valuations.where("date >= ?", @calc_start_date).order(date: :desc).select(:date, :value, :currency), :value)
      end

      def normalized_transactions
        newest_valuation_date = [ @calc_start_date, normalized_valuations.first&.dig("date") ].compact.max
        @normalized_transactions ||= normalize_entries_to_account_currency(@account.transactions.where("date >= ?", newest_valuation_date).order(:date).select(:date, :amount, :currency), :amount)
      end
end
