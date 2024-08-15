class FixInvalidAccountableData < ActiveRecord::Migration[7.2]
  def up
    Account.all.each do |account|
      unless account.accountable
        puts "Generating new accountable for id=#{account.id}, name=#{account.name}, type=#{account.accountable_type}"
        new_accountable = Accountable.from_type(account.accountable_type).new
        account.update!(accountable: new_accountable)
      end
    end
  end

  def down
    # Not reversible
  end
end
