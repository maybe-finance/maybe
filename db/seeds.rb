# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# https://github.com/rails/rails/issues/29112#issuecomment-320653056
ApplicationRecord.reset_column_information

# Create the default user
family = Family.create_or_find_by(name: "The Maybe Family")
puts "Family created: #{family.name}"
user = User.create_or_find_by(email: "user@maybe.local") do |u|
  u.first_name = "Josh"
  u.last_name = "Maybe"
  u.password = "password"
  u.password_confirmation = "password"
  u.family_id = family.id
end
puts "User created: #{user.email} for family: #{family.name}"

# Create default currency
Currency.find_or_create_by(iso_code: "USD", name: "United States Dollar")

checking_account = Account::Depository.new
account = Account.create_or_find_by(
            name: "Seed Checking Account",
            accountable: checking_account,
            family: family,
            balance: 5000
          )
puts "Account created: #{account.name}"

valuations = [
  { date: 1.year.ago.to_date, value: 4200 },
  { date: 250.days.ago.to_date, value: 4500 },
  { date: 200.days.ago.to_date, value: 4444.96 }
]

account.valuations.upsert_all(valuations, unique_by: :index_valuations_on_account_id_and_date)

puts "Valuations created: #{valuations.count}"

transactions = [
  { date: Date.today - 27, amount: 7.56, name: "Starbucks" },
  { date: Date.today - 18, amount: -500, name: "Paycheck" },
  { date: Date.today - 18, amount: 18.20, name: "Walgreens" },
  { date: Date.today - 13, amount: 34.20, name: "Chipotle" },
  { date: Date.today - 9, amount: -200, name: "Birthday check" },
  { date: Date.today - 5, amount: 85.00, name: "Amazon stuff" }
]
transactions.each do |t|
  account.transactions.find_or_create_by(t)
end

puts "Transactions created: #{transactions.count}"
