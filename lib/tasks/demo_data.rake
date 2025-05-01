namespace :demo_data do
  desc "Creates or resets demo data used in development environment"
  task empty: :environment do
    families = [ "Demo Family 1" ]
    Demo::Generator.new.reset_and_clear_data!(families)
  end

  task new_user: :environment do
    families = [ "Demo Family 1" ]
    Demo::Generator.new.reset_and_clear_data!(families, require_onboarding: true)
  end

  task :reset, [ :count ] => :environment do |t, args|
    count = (args[:count] || 1).to_i
    families = count.times.map { |i| "Demo Family #{i + 1}" }
    Demo::Generator.new.reset_data!(families)
  end

  task multi_currency: :environment do
    families = [ "Demo Family 1", "Demo Family 2" ]
    Demo::Generator.new.generate_multi_currency_data!(families)
  end

  task basic_budget: :environment do
    families = [ "Demo Family 1" ]
    Demo::Generator.new.generate_basic_budget_data!(families)
  end
end
