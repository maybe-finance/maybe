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
      @generators[:account_generator].create_checking_accounts!(family, count: 1)
      @generators[:account_generator].create_credit_card_accounts!(family, count: 1)
    end

    # Create USD accounts for US-based transactions
    def create_usd_accounts!(family)
      family.accounts.create!(
        accountable: Depository.new,
        name: "USD Checking Account",
        balance: 3000,
        currency: "USD"
      )
    end

    # Create GBP accounts for UK-based transactions
    def create_gbp_accounts!(family)
      family.accounts.create!(
        accountable: Depository.new,
        name: "GBP Savings Account",
        balance: 5000,
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
      create_eur_transaction_patterns!(family)
      create_usd_transaction_patterns!(family)
      create_gbp_transaction_patterns!(family)

      puts "  - International transactions created across #{SUPPORTED_CURRENCIES.length} currencies"
    end

    # Create EUR transactions (primary currency patterns)
    def create_eur_transaction_patterns!(family)
      eur_accounts = family.accounts.where(currency: "EUR")

      eur_accounts.each do |account|
        next if account.accountable_type == "Investment"

        5.times do |i|
          @generators[:transaction_generator].create_transaction!(
            account: account,
            amount: random_positive_amount(20, 200),
            name: "EUR Transaction #{i + 1}",
            date: random_date_within_days(60),
            currency: "EUR"
          )
        end
      end
    end

    # Create USD transactions (US-based spending patterns)
    def create_usd_transaction_patterns!(family)
      usd_accounts = family.accounts.where(currency: "USD")

      usd_accounts.each do |account|
        3.times do |i|
          @generators[:transaction_generator].create_transaction!(
            account: account,
            amount: random_positive_amount(30, 150),
            name: "USD Transaction #{i + 1}",
            date: random_date_within_days(60),
            currency: "USD"
          )
        end
      end
    end

    # Create GBP transactions (UK-based spending patterns)
    def create_gbp_transaction_patterns!(family)
      gbp_accounts = family.accounts.where(currency: "GBP")

      gbp_accounts.each do |account|
        2.times do |i|
          @generators[:transaction_generator].create_transaction!(
            account: account,
            amount: random_positive_amount(25, 100),
            name: "GBP Transaction #{i + 1}",
            date: random_date_within_days(60),
            currency: "GBP"
          )
        end
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
