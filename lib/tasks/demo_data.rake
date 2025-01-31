namespace :demo_data do
  desc "Creates or resets demo data used in development environment"
  task empty: :environment do
    families = [ "Demo Family 1" ]
    Demo::Generator.new.reset_and_clear_data!(families)
  end

  task reset: :environment do
    families = [ "Demo Family 1", "Demo Family 2", "Demo Family 3", "Demo Family 4", "Demo Family 5" ]
    Demo::Generator.new.reset_data!(families)
  end
end
