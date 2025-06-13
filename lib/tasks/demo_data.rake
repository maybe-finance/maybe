namespace :demo_data do
  desc "Creates a family with no financial data. Use for testing empty data states."
  task empty: :environment do
    Demo::Generator.new.generate_empty_data!
  end

  desc "Creates a family that needs onboarding. Use for testing onboarding flows."
  task new_user: :environment do
    Demo::Generator.new.generate_new_user_data!
  end

  desc "Creates comprehensive realistic demo data with multi-currency accounts"
  task default: :environment do
    Demo::Generator.new.generate_default_data!
  end
end
