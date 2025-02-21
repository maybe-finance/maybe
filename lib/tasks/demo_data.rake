namespace :demo_data do
  desc "Creates or resets demo data used in development environment"
  task empty: :environment do
    families = [ "Demo Family 1" ]
    Demo::Generator.new.reset_and_clear_data!(families)
  end

  task :reset, [ :count ] => :environment do |t, args|
    count = (args[:count] || 1).to_i
    families = count.times.map { |i| "Demo Family #{i + 1}" }
    Demo::Generator.new.reset_data!(families)
  end

  task multi_currency: :environment do
    Demo::Generator.new.generate_multi_currency_data!
  end
end
