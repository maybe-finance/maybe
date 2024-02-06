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
family = Family.create_or_find_by!(name: "The Smiths")
puts "Family created: #{family.name}"
user = User.create_or_find_by!(first_name: "John", last_name: "Smith", email: "john@smith.com",
                   password: "password", password_confirmation: "password", family_id: family.id)
puts "User created: #{user.email} for family: #{family.name}"
