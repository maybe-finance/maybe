namespace :invite_code do
  desc 'Generate a new InviteCode'
  task generate: :environment do
    invite_code = InviteCode.create
    if invite_code.persisted?
      puts "A new InviteCode has been generated: #{invite_code.code}"
    else
      puts "Failed to generate a new InviteCode."
    end
  end
end
