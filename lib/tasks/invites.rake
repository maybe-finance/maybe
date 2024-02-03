namespace :invites do
  desc "Create an invitation code"
  task create: :environment do
    puts InviteCode.generate!
  end
end
