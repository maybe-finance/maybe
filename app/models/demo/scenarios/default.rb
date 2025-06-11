# Default demo scenario - comprehensive realistic data for product demonstrations
#
# This scenario creates a complete, realistic demo environment that showcases
# all of Maybe's features with believable data patterns. Ideal for:
# - Product demonstrations to potential users
# - UI/UX testing with realistic data volumes
# - Feature development with complete data sets
# - Screenshots and marketing materials
#
class Demo::Scenarios::Default < Demo::BaseScenario
  # Scenario characteristics and configuration
  SCENARIO_NAME = "Comprehensive Demo".freeze
  PURPOSE = "Complete realistic demo environment showcasing all Maybe features".freeze
  TARGET_ACCOUNTS_PER_FAMILY = 7 # 1 each: checking, savings, credit card, 3 investments, 1 property+mortgage
  TARGET_TRANSACTIONS_PER_FAMILY = 50 # Realistic 3-month transaction history
  INCLUDES_SECURITIES = true
  INCLUDES_TRANSFERS = true
  INCLUDES_RULES = true

  private

    # Load securities before generating family data
    # Securities are needed for investment account trades
    def setup(**options)
      @generators[:security_generator].load_securities!
      puts "Securities loaded for investment accounts"
    end

    # Generate complete family financial data
    # Creates all account types with realistic balances and transaction patterns
    #
    # @param family [Family] The family to generate data for
    # @param options [Hash] Additional options (unused in this scenario)
    def generate_family_data!(family, **options)
      create_foundational_data!(family)
      create_all_account_types!(family)
      create_realistic_transaction_patterns!(family)
      create_account_transfers!(family)
    end

    # Create rules, tags, categories, and merchants for the family
    def create_foundational_data!(family)
      @generators[:rule_generator].create_rules!(family)
      @generators[:rule_generator].create_tags!(family)
      @generators[:rule_generator].create_categories!(family)
      @generators[:rule_generator].create_merchants!(family)
      puts "  - Rules, categories, and merchants created"
    end

    # Create one of each major account type to demonstrate full feature set
    def create_all_account_types!(family)
      @generators[:account_generator].create_credit_card_accounts!(family)
      @generators[:account_generator].create_checking_accounts!(family)
      @generators[:account_generator].create_savings_accounts!(family)
      @generators[:account_generator].create_investment_accounts!(family)
      @generators[:account_generator].create_properties_and_mortgages!(family)
      @generators[:account_generator].create_vehicles_and_loans!(family)
      @generators[:account_generator].create_other_accounts!(family)
      puts "  - All #{TARGET_ACCOUNTS_PER_FAMILY} account types created"
    end

    # Generate realistic transaction patterns across all accounts
    def create_realistic_transaction_patterns!(family)
      @generators[:transaction_generator].create_realistic_transactions!(family)
      puts "  - Realistic transaction patterns created (~#{TARGET_TRANSACTIONS_PER_FAMILY} transactions)"
    end

    # Create transfer patterns between accounts (credit card payments, investments, etc.)
    def create_account_transfers!(family)
      @generators[:transfer_generator].create_transfer_transactions!(family)
      puts "  - Account transfer patterns created"
    end

    def scenario_name
      SCENARIO_NAME
    end
end
