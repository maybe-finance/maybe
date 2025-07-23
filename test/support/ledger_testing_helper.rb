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
      balance: account[:balance] || 0, # Doesn't matter, ledger derives this
      cash_balance: account[:cash_balance] || 0, # Doesn't matter, ledger derives this
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

  def assert_calculated_ledger_balances(calculated_data:, expected_data:)
    # Convert expected data to a hash for easier lookup
    # Structure: [ { date:, legacy_balances: { balance:, cash_balance: }, balances: { start:, start_cash:, etc... }, flows: { ... }, adjustments: { ... } } ]
    expected_hash = {}
    expected_data.each do |data|
      expected_hash[data[:date].to_date] = {
        legacy_balances: data[:legacy_balances] || {},
        balances: data[:balances] || {},
        flows: data[:flows] || {},
        adjustments: data[:adjustments] || {}
      }
    end

    # Get all unique dates from all data sources
    all_dates = (calculated_data.map(&:date) + expected_hash.keys).uniq.sort

    # Check each date
    all_dates.each do |date|
      calculated_balance = calculated_data.find { |b| b.date == date }
      expected = expected_hash[date]

      if expected
        assert calculated_balance, "Expected balance for #{date} but none was calculated"

        # Always assert flows_factor is correct based on account classification
        expected_flows_factor = calculated_balance.account.classification == "asset" ? 1 : -1
        assert_equal expected_flows_factor, calculated_balance.flows_factor,
          "Flows factor mismatch for #{date}: expected #{expected_flows_factor} for #{calculated_balance.account.classification} account"

        legacy_balances = expected[:legacy_balances]
        balances = expected[:balances]
        flows = expected[:flows]
        adjustments = expected[:adjustments]

        # Legacy balance assertions
        if legacy_balances.any?
          assert_equal legacy_balances[:balance], calculated_balance.balance,
            "Balance mismatch for #{date}"

          assert_equal legacy_balances[:cash_balance], calculated_balance.cash_balance,
            "Cash balance mismatch for #{date}"
        end

        # Balance assertions
        if balances.any?
          assert_equal balances[:start_cash], calculated_balance.start_cash_balance,
            "Start cash balance mismatch for #{date}" if balances.key?(:start_cash)

          assert_equal balances[:start_non_cash], calculated_balance.start_non_cash_balance,
            "Start non-cash balance mismatch for #{date}" if balances.key?(:start_non_cash)

          # Calculate end_cash_balance using the formula from the migration
          if balances.key?(:end_cash)
            # Determine flows_factor based on account classification
            flows_factor = calculated_balance.account.classification == "asset" ? 1 : -1
            expected_end_cash = calculated_balance.start_cash_balance +
                               ((calculated_balance.cash_inflows - calculated_balance.cash_outflows) * flows_factor) +
                               calculated_balance.cash_adjustments
            assert_equal balances[:end_cash], expected_end_cash,
              "End cash balance mismatch for #{date}"
          end

          # Calculate end_non_cash_balance using the formula from the migration
          if balances.key?(:end_non_cash)
            # Determine flows_factor based on account classification
            flows_factor = calculated_balance.account.classification == "asset" ? 1 : -1
            expected_end_non_cash = calculated_balance.start_non_cash_balance +
                                   ((calculated_balance.non_cash_inflows - calculated_balance.non_cash_outflows) * flows_factor) +
                                   calculated_balance.net_market_flows +
                                   calculated_balance.non_cash_adjustments
            assert_equal balances[:end_non_cash], expected_end_non_cash,
              "End non-cash balance mismatch for #{date}"
          end

          # Calculate start_balance using the formula from the migration
          if balances.key?(:start)
            expected_start = calculated_balance.start_cash_balance + calculated_balance.start_non_cash_balance
            assert_equal balances[:start], expected_start,
              "Start balance mismatch for #{date}"
          end

          # Calculate end_balance using the formula from the migration since we're not persisting balances,
          # and generated columns are not available until the record is persisted
          if balances.key?(:end)
            # Determine flows_factor based on account classification
            flows_factor = calculated_balance.account.classification == "asset" ? 1 : -1
            expected_end_cash_component = calculated_balance.start_cash_balance +
                                         ((calculated_balance.cash_inflows - calculated_balance.cash_outflows) * flows_factor) +
                                         calculated_balance.cash_adjustments
            expected_end_non_cash_component = calculated_balance.start_non_cash_balance +
                                             ((calculated_balance.non_cash_inflows - calculated_balance.non_cash_outflows) * flows_factor) +
                                             calculated_balance.net_market_flows +
                                             calculated_balance.non_cash_adjustments
            expected_end = expected_end_cash_component + expected_end_non_cash_component
            assert_equal balances[:end], expected_end,
              "End balance mismatch for #{date}"
          end
        end

        # Flow assertions
        # If flows passed is 0, we assert all columns are 0
        if flows.is_a?(Integer) && flows == 0
          assert_equal 0, calculated_balance.cash_inflows,
            "Cash inflows mismatch for #{date}"

          assert_equal 0, calculated_balance.cash_outflows,
            "Cash outflows mismatch for #{date}"

          assert_equal 0, calculated_balance.non_cash_inflows,
            "Non-cash inflows mismatch for #{date}"

          assert_equal 0, calculated_balance.non_cash_outflows,
            "Non-cash outflows mismatch for #{date}"

          assert_equal 0, calculated_balance.net_market_flows,
            "Net market flows mismatch for #{date}"
        elsif flows.is_a?(Hash) && flows.any?
          # Cash flows - must be asserted together
          if flows.key?(:cash_inflows) || flows.key?(:cash_outflows)
            assert flows.key?(:cash_inflows) && flows.key?(:cash_outflows),
              "Cash inflows and outflows must be asserted together for #{date}"

            assert_equal flows[:cash_inflows], calculated_balance.cash_inflows,
              "Cash inflows mismatch for #{date}"

            assert_equal flows[:cash_outflows], calculated_balance.cash_outflows,
              "Cash outflows mismatch for #{date}"
          end

          # Non-cash flows - must be asserted together
          if flows.key?(:non_cash_inflows) || flows.key?(:non_cash_outflows)
            assert flows.key?(:non_cash_inflows) && flows.key?(:non_cash_outflows),
              "Non-cash inflows and outflows must be asserted together for #{date}"

            assert_equal flows[:non_cash_inflows], calculated_balance.non_cash_inflows,
              "Non-cash inflows mismatch for #{date}"

            assert_equal flows[:non_cash_outflows], calculated_balance.non_cash_outflows,
              "Non-cash outflows mismatch for #{date}"
          end

          # Market flows - can be asserted independently
          if flows.key?(:net_market_flows)
            assert_equal flows[:net_market_flows], calculated_balance.net_market_flows,
              "Net market flows mismatch for #{date}"
          end
        end

        # Adjustment assertions
        if adjustments.is_a?(Integer) && adjustments == 0
          assert_equal 0, calculated_balance.cash_adjustments,
            "Cash adjustments mismatch for #{date}"

          assert_equal 0, calculated_balance.non_cash_adjustments,
            "Non-cash adjustments mismatch for #{date}"
        elsif adjustments.is_a?(Hash) && adjustments.any?
          assert_equal adjustments[:cash_adjustments], calculated_balance.cash_adjustments,
            "Cash adjustments mismatch for #{date}" if adjustments.key?(:cash_adjustments)

          assert_equal adjustments[:non_cash_adjustments], calculated_balance.non_cash_adjustments,
            "Non-cash adjustments mismatch for #{date}" if adjustments.key?(:non_cash_adjustments)
        end

        # Temporary assertions during migration (remove after migration complete)
        # TODO: Remove these assertions after migration is complete
        # Since we're not persisting balances, we calculate the end values
        flows_factor = calculated_balance.account.classification == "asset" ? 1 : -1
        expected_end_cash = calculated_balance.start_cash_balance +
                           ((calculated_balance.cash_inflows - calculated_balance.cash_outflows) * flows_factor) +
                           calculated_balance.cash_adjustments
        expected_end_balance = expected_end_cash +
                              calculated_balance.start_non_cash_balance +
                              ((calculated_balance.non_cash_inflows - calculated_balance.non_cash_outflows) * flows_factor) +
                              calculated_balance.net_market_flows +
                              calculated_balance.non_cash_adjustments

        assert_equal calculated_balance.cash_balance, expected_end_cash,
          "Temporary assertion failed: end_cash_balance should equal cash_balance for #{date}"

        assert_equal calculated_balance.balance, expected_end_balance,
          "Temporary assertion failed: end_balance should equal balance for #{date}"
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
