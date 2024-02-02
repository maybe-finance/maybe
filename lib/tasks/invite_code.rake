# frozen_string_literal: true

namespace :invite_code do
  desc "Generates invite code"
  task generate: :environment do
    invite_code = InviteCode.create!
    puts "Code: #{invite_code.code}"
  end
end
