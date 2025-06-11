namespace :demo_data do
  desc "Creates a new user with no data. Use for testing empty data states."
  task empty: :environment do
    families = [ "Demo Family 1" ]
    Demo::Generator.new.reset_and_clear_data!(families)
  end

  desc "Creates a new user who has to go through onboarding still. Use for testing onboarding flows."
  task new_user: :environment do
    families = [ "Demo Family 1" ]
    Demo::Generator.new.reset_and_clear_data!(families, require_onboarding: true)
  end

  desc "General data reset that loads semi-realistic data"
  task :reset, [ :count ] => :environment do |t, args|
    count = (args[:count] || 1).to_i
    families = count.times.map { |i| "Demo Family #{i + 1}" }
    Demo::Generator.new.reset_data!(families)
  end

  desc "Use this when you need to test multi-currency features of the app with a minimal setup"
  task multi_currency: :environment do
    families = [ "Demo Family 1", "Demo Family 2" ]
    Demo::Generator.new.generate_multi_currency_data!(families)
  end

  desc "Use this when you want realistic budget data"
  task basic_budget: :environment do
    families = [ "Demo Family 1" ]
    Demo::Generator.new.generate_basic_budget_data!(families)
  end

  desc "Generates realistic data for 500 families for performance testing. Creates 1 family with Ruby, then efficiently duplicates it 499 times using SQL bulk operations."
  task performance_testing: :environment do
    families = [ "Performance Family 1" ]
    Demo::Generator.new.generate_performance_testing_data!(families)
  end
end
