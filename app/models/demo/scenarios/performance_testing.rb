# Performance testing scenario - high-volume data for load testing
#
# This scenario creates large volumes of realistic data to test application
# performance under load. Uses an efficient approach: generates one complete
# realistic family in Ruby, then uses SQL bulk operations to duplicate it
# 499 times for maximum performance. Ideal for:
# - Performance testing and benchmarking
# - Load testing database operations
# - UI performance testing with large datasets
# - Scalability validation at production scale
#

require "bcrypt"

class Demo::Scenarios::PerformanceTesting < Demo::BaseScenario
  # Scenario characteristics and configuration
  SCENARIO_NAME = "Performance Testing".freeze
  PURPOSE = "High-volume data generation for performance testing and load validation".freeze
  TARGET_FAMILIES = 500
  TARGET_ACCOUNTS_PER_FAMILY = 29 # 3 credit cards, 5 checking, 2 savings, 10 investments, 2 properties+mortgages, 3 vehicles+2 loans, 4 other assets+liabilities
  TARGET_TRANSACTIONS_PER_FAMILY = 200 # Reasonable volume for development performance testing
  TARGET_TRANSFERS_PER_FAMILY = 10
  SECURITIES_COUNT = 50 # Large number for investment account testing
  INCLUDES_SECURITIES = true
  INCLUDES_TRANSFERS = true
  INCLUDES_RULES = true

  # Override generate! to use our efficient bulk duplication approach
  def generate!(families, **options)
    puts "Creating performance test data for #{TARGET_FAMILIES} families using efficient bulk duplication..."

    setup(**options) if respond_to?(:setup, true)

    # Step 1: Create one complete realistic family
    template_family = create_template_family!(families.first, **options)

    # Step 2: Efficiently duplicate it 499 times using SQL
    duplicate_family_data!(template_family, TARGET_FAMILIES - 1)

    puts "Performance test data created successfully with #{TARGET_FAMILIES} families!"
  end

  private

    # Load large number of securities before generating family data
    def setup(**options)
      @generators[:security_generator].load_securities!(count: SECURITIES_COUNT)
      puts "#{SECURITIES_COUNT} securities loaded for performance testing"
    end

    # Create one complete, realistic family that will serve as our template
    def create_template_family!(family_or_name, **options)
      # Handle both Family object and family name string
      family = if family_or_name.is_a?(Family)
        family_or_name
      else
        Family.find_by(name: family_or_name)
      end

      unless family
        raise "Template family '#{family_or_name}' not found. Ensure family creation happened first."
      end

      puts "Creating template family: #{family.name}..."
      generate_family_data!(family, **options)

      puts "Template family created with #{family.accounts.count} accounts and #{family.entries.count} entries"
      family
    end

    # Efficiently duplicate the template family data using SQL bulk operations
    def duplicate_family_data!(template_family, copies_needed)
      puts "Duplicating template family #{copies_needed} times using efficient SQL operations..."

      ActiveRecord::Base.transaction do
        # Get all related data for the template family
        template_data = extract_template_data(template_family)

        # Create family records in batches
        create_family_copies(template_family, copies_needed)

        # Bulk duplicate all related data
        duplicate_accounts_and_related_data(template_data, copies_needed)
      end

      puts "Successfully created #{copies_needed} family copies"
    end

    # Extract all data related to the template family for duplication
    def extract_template_data(family)
      {
        accounts: family.accounts.includes(:accountable),
        entries: family.entries.includes(:entryable),
        categories: family.categories,
        merchants: family.merchants,
        tags: family.tags,
        rules: family.rules,
        holdings: family.holdings
      }
    end

    # Create family and user records efficiently
    def create_family_copies(template_family, count)
      puts "Creating #{count} family records..."

      families_data = []
      users_data = []
      password_digest = BCrypt::Password.create("password")

      (2..count + 1).each do |i|
        family_id = SecureRandom.uuid
        family_name = "Performance Family #{i}"

        families_data << {
          id: family_id,
          name: family_name,
          currency: template_family.currency,
          locale: template_family.locale,
          country: template_family.country,
          timezone: template_family.timezone,
          date_format: template_family.date_format,
          created_at: Time.current,
          updated_at: Time.current
        }

        # Create admin user
        users_data << {
          id: SecureRandom.uuid,
          family_id: family_id,
          email: "user#{i}@maybe.local",
          first_name: "Demo",
          last_name: "User",
          role: "admin",
          password_digest: password_digest,
          onboarded_at: Time.current,
          created_at: Time.current,
          updated_at: Time.current
        }

        # Create member user
        users_data << {
          id: SecureRandom.uuid,
          family_id: family_id,
          email: "member_user#{i}@maybe.local",
          first_name: "Demo (member user)",
          last_name: "User",
          role: "member",
          password_digest: password_digest,
          onboarded_at: Time.current,
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      # Bulk insert families and users
      Family.insert_all(families_data)
      User.insert_all(users_data)

      puts "Created #{count} families and #{users_data.length} users"
    end

    # Efficiently duplicate accounts and all related data using SQL
    def duplicate_accounts_and_related_data(template_data, count)
      puts "Duplicating accounts and related data for #{count} families..."

      new_families = Family.where("name LIKE 'Performance Family %'")
                           .where.not(id: template_data[:accounts].first&.family_id)
                           .limit(count)

      new_families.find_each.with_index do |family, index|
        duplicate_family_accounts_bulk(template_data, family)
        puts "Completed family #{index + 1}/#{count}" if (index + 1) % 50 == 0
      end
    end

    # Duplicate all accounts and related data for a single family using bulk operations
    def duplicate_family_accounts_bulk(template_data, target_family)
      return if template_data[:accounts].empty?

      account_id_mapping = {}

      # Create accounts one by one to handle accountables properly
      template_data[:accounts].each do |template_account|
        new_account = target_family.accounts.create!(
          accountable: template_account.accountable.dup,
          name: template_account.name,
          balance: template_account.balance,
          currency: template_account.currency,
          subtype: template_account.subtype,
          is_active: template_account.is_active
        )
        account_id_mapping[template_account.id] = new_account.id
      end

      # Bulk create other related data
      create_bulk_categories(template_data[:categories], target_family)
      create_bulk_entries_and_related(template_data, target_family, account_id_mapping)
    rescue => e
      puts "Error duplicating data for #{target_family.name}: #{e.message}"
      # Continue with next family rather than failing completely
    end

    # Bulk create categories for a family
    def create_bulk_categories(template_categories, target_family)
      return if template_categories.empty?

      # Create mapping from old category IDs to new category IDs
      category_id_mapping = {}

      # First pass: generate new IDs for all categories
      template_categories.each do |template_category|
        category_id_mapping[template_category.id] = SecureRandom.uuid
      end

      # Second pass: create category data with properly mapped parent_ids
      categories_data = template_categories.map do |template_category|
        # Map parent_id to the new family's category ID, or nil if no parent
        new_parent_id = template_category.parent_id ? category_id_mapping[template_category.parent_id] : nil

        {
          id: category_id_mapping[template_category.id],
          family_id: target_family.id,
          name: template_category.name,
          color: template_category.color,
          classification: template_category.classification,
          parent_id: new_parent_id,
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      Category.insert_all(categories_data)
    end

    # Bulk create entries and related entryables
    def create_bulk_entries_and_related(template_data, target_family, account_id_mapping)
      return if template_data[:entries].empty?

      entries_data = []
      transactions_data = []
      trades_data = []

      template_data[:entries].each do |template_entry|
        new_account_id = account_id_mapping[template_entry.account_id]
        next unless new_account_id

        new_entry_id = SecureRandom.uuid
        new_entryable_id = SecureRandom.uuid

        entries_data << {
          id: new_entry_id,
          account_id: new_account_id,
          entryable_type: template_entry.entryable_type,
          entryable_id: new_entryable_id,
          name: template_entry.name,
          date: template_entry.date,
          amount: template_entry.amount,
          currency: template_entry.currency,
          notes: template_entry.notes,
          created_at: Time.current,
          updated_at: Time.current
        }

        # Create entryable data based on type
        case template_entry.entryable_type
        when "Transaction"
          transactions_data << {
            id: new_entryable_id,
            created_at: Time.current,
            updated_at: Time.current
          }
        when "Trade"
          trades_data << {
            id: new_entryable_id,
            security_id: template_entry.entryable.security_id,
            qty: template_entry.entryable.qty,
            price: template_entry.entryable.price,
            currency: template_entry.entryable.currency,
            created_at: Time.current,
            updated_at: Time.current
          }
        end
      end

      # Bulk insert all data
      Entry.insert_all(entries_data) if entries_data.any?
      Transaction.insert_all(transactions_data) if transactions_data.any?
      Trade.insert_all(trades_data) if trades_data.any?
    end

    # Generate high-volume family data for the template family
    def generate_family_data!(family, **options)
      create_foundational_data!(family)
      create_high_volume_accounts!(family)
      create_performance_transactions!(family)
      create_performance_transfers!(family)
    end

    # Create rules, tags, categories and merchants for performance testing
    def create_foundational_data!(family)
      @generators[:rule_generator].create_tags!(family)
      @generators[:rule_generator].create_categories!(family)
      @generators[:rule_generator].create_merchants!(family)
      @generators[:rule_generator].create_rules!(family)
      puts "  - Foundational data created (tags, categories, merchants, rules)"
    end

    # Create large numbers of accounts across all types for performance testing
    def create_high_volume_accounts!(family)
      @generators[:account_generator].create_credit_card_accounts!(family, count: 3)
      puts "  - 3 credit card accounts created"

      @generators[:account_generator].create_checking_accounts!(family, count: 5)
      puts "  - 5 checking accounts created"

      @generators[:account_generator].create_savings_accounts!(family, count: 2)
      puts "  - 2 savings accounts created"

      @generators[:account_generator].create_investment_accounts!(family, count: 10)
      puts "  - 10 investment accounts created"

      @generators[:account_generator].create_properties_and_mortgages!(family, count: 2)
      puts "  - 2 properties and mortgages created"

      @generators[:account_generator].create_vehicles_and_loans!(family, vehicle_count: 3, loan_count: 2)
      puts "  - 3 vehicles and 2 loans created"

      @generators[:account_generator].create_other_accounts!(family, asset_count: 4, liability_count: 4)
      puts "  - 4 other assets and 4 other liabilities created"

      puts "  - Total: #{TARGET_ACCOUNTS_PER_FAMILY} accounts created for performance testing"
    end

    # Create high-volume transactions for performance testing
    def create_performance_transactions!(family)
      @generators[:transaction_generator].create_performance_transactions!(family)
      puts "  - High-volume performance transactions created (~#{TARGET_TRANSACTIONS_PER_FAMILY} transactions)"
    end

    # Create multiple transfer cycles for performance testing
    def create_performance_transfers!(family)
      @generators[:transfer_generator].create_transfer_transactions!(family, count: TARGET_TRANSFERS_PER_FAMILY)
      puts "  - #{TARGET_TRANSFERS_PER_FAMILY} transfer transaction cycles created"
    end

    def scenario_name
      SCENARIO_NAME
    end
end
