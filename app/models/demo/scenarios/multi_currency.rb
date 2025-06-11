# Multi-currency scenario - international financial management demonstration
#
# This scenario creates accounts and transactions in multiple currencies to showcase
# Maybe's multi-currency capabilities. Demonstrates currency conversion, international
# transactions, and mixed-currency portfolio management. Ideal for:
# - International users and use cases
# - Currency conversion feature testing
# - Multi-region financial management demos
# - Exchange rate and conversion testing
#
# Primary currency is EUR with additional USD and GBP accounts and transactions.
#
class Demo::Scenarios::MultiCurrency < Demo::BaseScenario
  include Demo::DataHelper

  # Scenario characteristics and configuration
  SCENARIO_NAME = "Multi-Currency".freeze
  PURPOSE = "International financial management with multiple currencies".freeze
  PRIMARY_CURRENCY = "EUR".freeze
  SUPPORTED_CURRENCIES = %w[EUR USD GBP].freeze
  TARGET_ACCOUNTS_PER_FAMILY = 5 # 2 EUR (checking, credit), 1 USD, 1 GBP, 1 multi-currency investment
  TARGET_TRANSACTIONS_PER_FAMILY = 10 # Distributed across currencies
  INCLUDES_SECURITIES = false # Keep simple for currency focus
  INCLUDES_TRANSFERS = true # Minimal transfers to avoid currency complexity
  INCLUDES_RULES = false # Focus on currency, not categorization

  private

    # Generate family data with multiple currencies
    # Creates accounts in EUR, USD, and GBP with appropriate transactions
    #
    # @param family [Family] The family to generate data for (should have EUR as primary currency)
    # @param options [Hash] Additional options (unused in this scenario)
    def generate_family_data!(family, **options)
      create_basic_categorization!(family)
      create_multi_currency_accounts!(family)
      create_international_transactions!(family)
      create_minimal_transfers!(family)
    end

    # Create basic categories for international transactions
    def create_basic_categorization!(family)
      @generators[:rule_generator].create_categories!(family)
      @generators[:rule_generator].create_merchants!(family)
      puts "  - Basic categories and merchants created for international transactions"
    end

    # Create accounts in multiple currencies to demonstrate international capabilities
    def create_multi_currency_accounts!(family)
      create_eur_accounts!(family)      # Primary currency accounts
      create_usd_accounts!(family)      # US dollar accounts
      create_gbp_accounts!(family)      # British pound accounts
      create_investment_account!(family) # Multi-currency investment

      puts "  - #{TARGET_ACCOUNTS_PER_FAMILY} multi-currency accounts created (#{SUPPORTED_CURRENCIES.join(', ')})"
    end

    # Create EUR accounts (primary currency for this scenario)
    def create_eur_accounts!(family)
      # Create EUR checking account
      family.accounts.create!(
        accountable: Depository.new,
        name: "EUR Checking Account",
        balance: 0, # Will be calculated from transactions
        currency: "EUR"
      )

      # Create EUR credit card
      family.accounts.create!(
        accountable: CreditCard.new,
        name: "EUR Credit Card",
        balance: 0, # Will be calculated from transactions
        currency: "EUR"
      )
    end

    # Create USD accounts for US-based transactions
    def create_usd_accounts!(family)
      family.accounts.create!(
        accountable: Depository.new,
        name: "USD Checking Account",
        balance: 0, # Will be calculated from transactions
        currency: "USD"
      )
    end

    # Create GBP accounts for UK-based transactions
    def create_gbp_accounts!(family)
      family.accounts.create!(
        accountable: Depository.new,
        name: "GBP Savings Account",
        balance: 0, # Will be calculated from transactions
        currency: "GBP",
        subtype: "savings"
      )
    end

    # Create investment account (uses primary currency)
    def create_investment_account!(family)
      @generators[:account_generator].create_investment_accounts!(family, count: 1)
    end

    # Create transactions in various currencies to demonstrate international usage
    def create_international_transactions!(family)
      # Create initial valuations for accounts that need them
      create_initial_valuations!(family)

      create_eur_transaction_patterns!(family)
      create_usd_transaction_patterns!(family)
      create_gbp_transaction_patterns!(family)

      # Update account balances to match transaction sums
      @generators[:transaction_generator].update_account_balances_from_transactions!(family)

      puts "  - International transactions created across #{SUPPORTED_CURRENCIES.length} currencies"
    end

    # Create initial valuations for credit cards in this scenario
    def create_initial_valuations!(family)
      family.accounts.each do |account|
        next unless account.accountable_type == "CreditCard"

        Entry.create!(
          account: account,
          amount: 1000, # Initial credit card debt
          name: "Initial creditcard valuation",
          date: 2.years.ago.to_date,
          currency: account.currency,
          entryable_type: "Valuation",
          entryable_attributes: {}
        )
      end
    end

    # Create EUR transactions (primary currency patterns) with both income and expenses
    def create_eur_transaction_patterns!(family)
      eur_accounts = family.accounts.where(currency: "EUR")

      eur_accounts.each do |account|
        next if account.accountable_type == "Investment"

        if account.accountable_type == "CreditCard"
          # Credit cards only get purchases (positive amounts)
          5.times do |i|
            @generators[:transaction_generator].create_transaction!(
              account: account,
              amount: random_positive_amount(50, 300), # Purchases (positive)
              name: "EUR Purchase #{i + 1}",
              date: random_date_within_days(60),
              currency: "EUR"
            )
          end
        else
          # Checking accounts get both income and expenses
          # Create income transactions (negative amounts)
          2.times do |i|
            @generators[:transaction_generator].create_transaction!(
              account: account,
              amount: -random_positive_amount(2000, 3000), # Higher income to cover transfers
              name: "EUR Salary #{i + 1}",
              date: random_date_within_days(60),
              currency: "EUR"
            )
          end

          # Create expense transactions (positive amounts)
          3.times do |i|
            @generators[:transaction_generator].create_transaction!(
              account: account,
              amount: random_positive_amount(20, 200), # Expense (positive)
              name: "EUR Purchase #{i + 1}",
              date: random_date_within_days(60),
              currency: "EUR"
            )
          end
        end
      end
    end

    # Create USD transactions (US-based spending patterns) with both income and expenses
    def create_usd_transaction_patterns!(family)
      usd_accounts = family.accounts.where(currency: "USD")

      usd_accounts.each do |account|
        # Create income transaction (negative amount)
        @generators[:transaction_generator].create_transaction!(
          account: account,
          amount: -random_positive_amount(1500, 2500), # Higher income to cover transfers
          name: "USD Freelance Payment",
          date: random_date_within_days(60),
          currency: "USD"
        )

        # Create expense transactions (positive amounts)
        2.times do |i|
          @generators[:transaction_generator].create_transaction!(
            account: account,
            amount: random_positive_amount(30, 150), # Expense (positive)
            name: "USD Purchase #{i + 1}",
            date: random_date_within_days(60),
            currency: "USD"
          )
        end
      end
    end

    # Create GBP transactions (UK-based spending patterns) with both income and expenses
    def create_gbp_transaction_patterns!(family)
      gbp_accounts = family.accounts.where(currency: "GBP")

      gbp_accounts.each do |account|
        # Create income transaction (negative amount)
        @generators[:transaction_generator].create_transaction!(
          account: account,
          amount: -random_positive_amount(500, 800), # Income (negative)
          name: "GBP Consulting Payment",
          date: random_date_within_days(60),
          currency: "GBP"
        )

        # Create expense transaction (positive amount)
        @generators[:transaction_generator].create_transaction!(
          account: account,
          amount: random_positive_amount(25, 100), # Expense (positive)
          name: "GBP Purchase",
          date: random_date_within_days(60),
          currency: "GBP"
        )
      end
    end

    # Create minimal transfers to keep scenario focused on currency demonstration
    def create_minimal_transfers!(family)
      @generators[:transfer_generator].create_transfer_transactions!(family, count: 1)
      puts "  - Minimal account transfers created"
    end

    def scenario_name
      SCENARIO_NAME
    end
end
