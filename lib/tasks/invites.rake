namespace :invites do
  desc "Create an invite code"
  task create: :environment do
    puts InviteCode.generate!
  end
end
