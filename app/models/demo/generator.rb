class Demo::Generator
  include Demo::DataHelper

  # Public API - these methods are called by rake tasks and must be preserved
  def reset_and_clear_data!(family_names, require_onboarding: false)
    generate_for_scenario(:clean_slate, family_names, require_onboarding: require_onboarding)
  end

  def reset_data!(family_names)
    generate_for_scenario(:default, family_names)
  end

  def generate_performance_testing_data!(family_names)
    generate_for_scenario(:performance_testing, family_names)
  end

  def generate_basic_budget_data!(family_names)
    generate_for_scenario(:basic_budget, family_names)
  end

  def generate_multi_currency_data!(family_names)
    generate_for_scenario(:multi_currency, family_names)
  end

  private

    # Registry pattern for clean scenario lookup and easy extensibility
    def scenario_registry
      @scenario_registry ||= {
        clean_slate: Demo::Scenarios::CleanSlate,
        default: Demo::Scenarios::Default,
        basic_budget: Demo::Scenarios::BasicBudget,
        multi_currency: Demo::Scenarios::MultiCurrency,
        performance_testing: Demo::Scenarios::PerformanceTesting
      }.freeze
    end

    def generators
      @generators ||= {
        data_cleaner: Demo::DataCleaner.new,
        rule_generator: Demo::RuleGenerator.new,
        account_generator: Demo::AccountGenerator.new,
        transaction_generator: Demo::TransactionGenerator.new,
        security_generator: Demo::SecurityGenerator.new,
        transfer_generator: Demo::TransferGenerator.new
      }
    end

    def generate_for_scenario(scenario_key, family_names, **options)
      raise ArgumentError, "Scenario key is required" if scenario_key.nil?
      raise ArgumentError, "Family names must be provided" if family_names.nil? || family_names.empty?

      scenario_class = scenario_registry[scenario_key]
      unless scenario_class
        raise ArgumentError, "Unknown scenario: #{scenario_key}. Available: #{scenario_registry.keys.join(', ')}"
      end

      puts "Starting #{scenario_key} scenario generation for #{family_names.length} families..."

      clear_all_data!
      create_families_and_users!(family_names, **options)
      families = family_names.map { |name| Family.find_by(name: name) }

      scenario = scenario_class.new(generators)
      scenario.generate!(families, **options)

      # Sync families after generation (except for performance testing)
      unless scenario_key == :performance_testing
        puts "Running account sync for generated data..."
        families.each do |family|
          family.accounts.each do |account|
            sync = Sync.create!(syncable: account)
            sync.perform
          end
          puts "  - #{family.name} accounts synced (#{family.accounts.count} accounts)"
        end
      end

      puts "Demo data loaded successfully!"
    end

    def clear_all_data!
      family_count = Family.count

      if family_count > 200
        raise "Too much data to clear efficiently (#{family_count} families found). " \
              "Please run 'bundle exec rails db:reset' instead to quickly reset the database, " \
              "then re-run your demo data task."
      end

      generators[:data_cleaner].destroy_everything!
    end

    def create_families_and_users!(family_names, require_onboarding: false, currency: "USD")
      family_names.each_with_index do |family_name, index|
        create_family_and_user!(family_name, "user#{index == 0 ? "" : index + 1}@maybe.local",
                              currency: currency, require_onboarding: require_onboarding)
      end
      puts "Users reset"
    end

    def create_family_and_user!(family_name, user_email, currency: "USD", require_onboarding: false)
      base_uuid = "d99e3c6e-d513-4452-8f24-dc263f8528c0"
      id = Digest::UUID.uuid_v5(base_uuid, family_name)

      family = Family.create!(
        id: id,
        name: family_name,
        currency: currency,
        locale: "en",
        country: "US",
        timezone: "America/New_York",
        date_format: "%m-%d-%Y"
      )

      family.start_subscription!("sub_1234567890")

      family.users.create! \
        email: user_email,
        first_name: "Demo",
        last_name: "User",
        role: "admin",
        password: "password",
        onboarded_at: require_onboarding ? nil : Time.current

      family.users.create! \
        email: "member_#{user_email}",
        first_name: "Demo (member user)",
        last_name: "User",
        role: "member",
        password: "password",
        onboarded_at: require_onboarding ? nil : Time.current
    end
end
