# Basic budget scenario - minimal budgeting demonstration with categories
#
# This scenario creates a simple budget demonstration with parent/child categories
# and one transaction per category. Designed to showcase basic budgeting features
# without overwhelming complexity. Ideal for:
# - Basic budgeting feature demos
# - Category hierarchy demonstrations
# - Simple transaction categorization examples
# - Lightweight testing environments
#
class Demo::Scenarios::BasicBudget < Demo::BaseScenario
  include Demo::DataHelper

  # Scenario characteristics and configuration
  SCENARIO_NAME = "Basic Budget".freeze
  PURPOSE = "Simple budget demonstration with category hierarchy".freeze
  TARGET_ACCOUNTS_PER_FAMILY = 1 # Single checking account
  TARGET_TRANSACTIONS_PER_FAMILY = 4 # One income, three expenses
  TARGET_CATEGORIES = 4 # Income + 3 expense categories (with one subcategory)
  INCLUDES_SECURITIES = false
  INCLUDES_TRANSFERS = false
  INCLUDES_RULES = false

  private

    # Generate basic budget demonstration data
    # Creates simple category hierarchy and one transaction per category
    #
    # @param family [Family] The family to generate data for
    # @param options [Hash] Additional options (unused in this scenario)
    def generate_family_data!(family, **options)
      create_category_hierarchy!(family)
      create_demo_checking_account!(family)
      create_sample_categorized_transactions!(family)
    end

    # Create parent categories with one subcategory example
    def create_category_hierarchy!(family)
      # Create parent categories
      @food_category = family.categories.create!(
        name: "Food & Drink",
        color: random_color,
        classification: "expense"
      )

      @transport_category = family.categories.create!(
        name: "Transportation",
        color: random_color,
        classification: "expense"
      )

      # Create subcategory to demonstrate hierarchy
      @restaurants_category = family.categories.create!(
        name: "Restaurants",
        parent: @food_category,
        color: random_color,
        classification: "expense"
      )

      puts "  - #{TARGET_CATEGORIES} categories created (with parent/child hierarchy)"
    end

    # Create single checking account for budget demonstration
    def create_demo_checking_account!(family)
      @checking_account = family.accounts.create!(
        accountable: Depository.new,
        name: "Demo Checking",
        balance: 0, # Will be calculated from transactions
        currency: "USD"
      )

      puts "  - #{TARGET_ACCOUNTS_PER_FAMILY} demo checking account created"
    end

    # Create one transaction for each category to demonstrate categorization
    def create_sample_categorized_transactions!(family)
      # Create income category and transaction first
      income_category = family.categories.create!(
        name: "Income",
        color: random_color,
        classification: "income"
      )

      # Add income transaction (negative amount = inflow)
      @generators[:transaction_generator].create_transaction!(
        account: @checking_account,
        amount: -500, # Income (negative)
        name: "Salary",
        category: income_category,
        date: 5.days.ago
      )

      # Grocery transaction (parent category)
      @generators[:transaction_generator].create_transaction!(
        account: @checking_account,
        amount: 100,
        name: "Grocery Store",
        category: @food_category,
        date: 2.days.ago
      )

      # Restaurant transaction (subcategory)
      @generators[:transaction_generator].create_transaction!(
        account: @checking_account,
        amount: 50,
        name: "Restaurant Meal",
        category: @restaurants_category,
        date: 1.day.ago
      )

      # Transportation transaction
      @generators[:transaction_generator].create_transaction!(
        account: @checking_account,
        amount: 20,
        name: "Gas Station",
        category: @transport_category,
        date: Date.current
      )

      # Update account balance to match transaction sum
      @generators[:transaction_generator].update_account_balances_from_transactions!(family)

      puts "  - #{TARGET_TRANSACTIONS_PER_FAMILY + 1} categorized transactions created (including income)"
    end

    def scenario_name
      SCENARIO_NAME
    end
end
