# Clean slate scenario - minimal starter data for new user onboarding
#
# This scenario creates the absolute minimum data needed to help new users
# understand Maybe's core features without overwhelming them. Ideal for:
# - New user onboarding flows
# - Tutorial walkthroughs
# - Clean development environments
# - User acceptance testing with minimal data
#
# The scenario only generates data when explicitly requested via with_minimal_data: true,
# otherwise it creates no data at all (true "clean slate").
#
# @example Minimal data generation
#   scenario = Demo::Scenarios::CleanSlate.new(generators)
#   scenario.generate!(families, with_minimal_data: true)
#
# @example True clean slate (no data)
#   scenario = Demo::Scenarios::CleanSlate.new(generators)
#   scenario.generate!(families) # Creates nothing
#
class Demo::Scenarios::CleanSlate < Demo::BaseScenario
  # Scenario characteristics and configuration
  SCENARIO_NAME = "Clean Slate".freeze
  PURPOSE = "Minimal starter data for new user onboarding and tutorials".freeze
  TARGET_ACCOUNTS_PER_FAMILY = 1 # Single checking account only
  TARGET_TRANSACTIONS_PER_FAMILY = 3 # Just enough to show transaction history
  INCLUDES_SECURITIES = false
  INCLUDES_TRANSFERS = false
  INCLUDES_RULES = false
  MINIMAL_CATEGORIES = 2 # Essential expense and income categories only

  # Override the base generate! method to handle the special with_minimal_data option
  # Only generates data when explicitly requested to avoid accidental data creation
  #
  # @param families [Array<Family>] Families to generate data for
  # @param options [Hash] Options hash that may contain with_minimal_data or require_onboarding
  def generate!(families, **options)
    # For "empty" task, don't generate any data
    # For "new_user" task, generate minimal data for onboarding users
    with_minimal_data = options[:with_minimal_data] || options[:require_onboarding]
    return unless with_minimal_data

    super(families, **options)
  end

  private

    # Generate minimal family data for getting started
    # Creates only essential accounts and transactions to demonstrate core features
    #
    # @param family [Family] The family to generate data for
    # @param options [Hash] Additional options (with_minimal_data used for validation)
    def generate_family_data!(family, **options)
      create_essential_categories!(family)
      create_primary_checking_account!(family)
      create_sample_transaction_history!(family)
    end

    # Create only the most essential categories for basic expense tracking
    def create_essential_categories!(family)
      @food_category = family.categories.create!(
        name: "Food & Drink",
        color: "#4da568",
        classification: "expense"
      )

      @income_category = family.categories.create!(
        name: "Income",
        color: "#6471eb",
        classification: "income"
      )

      puts "  - #{MINIMAL_CATEGORIES} essential categories created"
    end

    # Create a single primary checking account with a reasonable starting balance
    def create_primary_checking_account!(family)
      @checking_account = family.accounts.create!(
        accountable: Depository.new,
        name: "Main Checking",
        balance: 0, # Will be calculated from transactions
        currency: "USD"
      )

      puts "  - #{TARGET_ACCOUNTS_PER_FAMILY} primary checking account created"
    end

    # Create minimal transaction history showing income and expense patterns
    def create_sample_transaction_history!(family)
      # Recent salary deposit
      @generators[:transaction_generator].create_transaction!(
        account: @checking_account,
        amount: -3000, # Income (negative = inflow)
        name: "Salary",
        category: @income_category,
        date: 15.days.ago
      )

      # Recent grocery purchase
      @generators[:transaction_generator].create_transaction!(
        account: @checking_account,
        amount: 75, # Expense (positive = outflow)
        name: "Grocery Store",
        category: @food_category,
        date: 5.days.ago
      )

      # Recent restaurant expense
      @generators[:transaction_generator].create_transaction!(
        account: @checking_account,
        amount: 45, # Expense
        name: "Restaurant",
        category: @food_category,
        date: 2.days.ago
      )

      # Update account balance to match transaction sum
      @generators[:transaction_generator].update_account_balances_from_transactions!(family)

      puts "  - #{TARGET_TRANSACTIONS_PER_FAMILY} sample transactions created"
    end

    def scenario_name
      SCENARIO_NAME
    end
end
