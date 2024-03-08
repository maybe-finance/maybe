# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create default currency
Currency.find_or_create_by(iso_code: "USD", name: "United States Dollar")

puts 'Run the following command to create demo data: `rake demo_data:reset`' if Rails.env.development?
