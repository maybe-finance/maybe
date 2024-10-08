namespace :invites do
  desc "Create invite code(s). Usage: rake invites:create[count]"
  task :create, [ :count ] => :environment do |_, args|
    count = (args[:count] || 1).to_i
    count.times do
      puts InviteCode.generate!
    end
  end
end
