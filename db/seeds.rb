# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

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

puts "seeding currencies"

currencies = YAML.load_file(Rails.root.join("test", "fixtures", "currencies.yml"))
currencies.each do |key, currency|
  Currency.create_or_find_by(currency)
  puts "Currency created: #{currency["name"]}"
end
