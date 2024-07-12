namespace :demo_data do
  desc "Creates or resets demo data used in development environment"
  task empty: :environment do
    Demo::Generator.new.reset_and_clear_data!
  end

  task reset: :environment do
    Demo::Generator.new.reset_data!
  end
end
