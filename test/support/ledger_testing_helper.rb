module LedgerTestingHelper
  def create_account_with_ledger(account:, entries: [], exchange_rates: [], security_prices: [], holdings: [])
    # Clear all exchange rates and security prices to ensure clean test environment
    ExchangeRate.destroy_all
    Security::Price.destroy_all

    # Create account with specified attributes
    account_attrs = account.except(:type)
    account_type = account[:type]

    # Create the account
    created_account = families(:empty).accounts.create!(
      name: "Test Account",
      accountable: account_type.new,
      **account_attrs
    )

    # Set up exchange rates if provided
    exchange_rates.each do |rate_data|
      ExchangeRate.create!(
        date: rate_data[:date],
        from_currency: rate_data[:from],
        to_currency: rate_data[:to],
        rate: rate_data[:rate]
      )
    end

    # Set up security prices if provided
    security_prices.each do |price_data|
      security = Security.find_or_create_by!(ticker: price_data[:ticker]) do |s|
        s.name = price_data[:ticker]
      end

      Security::Price.create!(
        security: security,
        date: price_data[:date],
        price: price_data[:price],
        currency: created_account.currency
      )
    end

    # Create entries in the order they were specified
    entries.each do |entry_data|
      case entry_data[:type]
      when "current_anchor", "opening_anchor", "reconciliation"
        # Create valuation entry
        created_account.entries.create!(
          name: "Valuation",
          date: entry_data[:date],
          amount: entry_data[:balance],
          currency: entry_data[:currency] || created_account.currency,
          entryable: Valuation.new(kind: entry_data[:type])
        )
      when "transaction"
        # Use account currency if not specified
        currency = entry_data[:currency] || created_account.currency

        created_account.entries.create!(
          name: "Transaction",
          date: entry_data[:date],
          amount: entry_data[:amount],
          currency: currency,
          entryable: Transaction.new
        )
      when "trade"
        # Find or create security
        security = Security.find_or_create_by!(ticker: entry_data[:ticker]) do |s|
          s.name = entry_data[:ticker]
        end

        # Use account currency if not specified
        currency = entry_data[:currency] || created_account.currency

        trade = Trade.new(
          qty: entry_data[:qty],
          security: security,
          price: entry_data[:price],
          currency: currency
        )

        created_account.entries.create!(
          name: "Trade",
          date: entry_data[:date],
          amount: entry_data[:qty] * entry_data[:price],
          currency: currency,
          entryable: trade
        )
      end
    end

    # Create holdings if provided
    holdings.each do |holding_data|
      # Find or create security
      security = Security.find_or_create_by!(ticker: holding_data[:ticker]) do |s|
        s.name = holding_data[:ticker]
      end

      Holding.create!(
        account: created_account,
        security: security,
        date: holding_data[:date],
        qty: holding_data[:qty],
        price: holding_data[:price],
        amount: holding_data[:amount],
        currency: holding_data[:currency] || created_account.currency
      )
    end

    created_account
  end

  def assert_calculated_ledger_balances(calculated_data:, expected_balances:)
    # Convert expected balances to a hash for easier lookup
    expected_hash = expected_balances.to_h do |date, balance_data|
      [ date.to_date, balance_data ]
    end

    # Get all unique dates from both calculated and expected data
    all_dates = (calculated_data.map(&:date) + expected_hash.keys).uniq.sort

    # Check each date
    all_dates.each do |date|
      calculated_balance = calculated_data.find { |b| b.date == date }
      expected = expected_hash[date]

      if expected
        assert calculated_balance, "Expected balance for #{date} but none was calculated"

        if expected[:balance]
          assert_equal expected[:balance], calculated_balance.balance.to_d,
            "Balance mismatch for #{date}"
        end

        if expected[:cash_balance]
          assert_equal expected[:cash_balance], calculated_balance.cash_balance.to_d,
            "Cash balance mismatch for #{date}"
        end
      else
        assert_nil calculated_balance, "Unexpected balance calculated for #{date}"
      end
    end

    # Verify we got all expected dates
    expected_dates = expected_hash.keys.sort
    calculated_dates = calculated_data.map(&:date).sort

    expected_dates.each do |date|
      assert_includes calculated_dates, date,
        "Expected balance for #{date} was not in calculated data"
    end
  end
end
