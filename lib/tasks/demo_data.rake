namespace :demo_data do
  desc "Creates a family with no financial data. Use for testing empty data states."
  task empty: :environment do
    Demo::Generator.new.generate_empty_data!
  end

  desc "Creates a family that needs onboarding. Use for testing onboarding flows."
  task new_user: :environment do
    Demo::Generator.new.generate_new_user_data!
  end

  desc "Creates comprehensive realistic demo data with multi-currency accounts"
  task default: :environment do
    Demo::Generator.new.generate_default_data!

    # Verify balances after generation and sync
    puts "\n🔍 Verifying account balances..."
    family = Family.last

    # Reload accounts and balances to get post-sync data
    family.accounts.reload.includes(:balances).each do |account|
      latest_balance = account.balances.order(:date).last&.balance || 0
      status = if account.asset?
        latest_balance >= 0 ? "✅" : "❌"
      else # liability
        latest_balance >= 0 ? "✅" : "❌" # Positive balance = debt owed (correct for liabilities)
      end
      puts "#{status} #{account.name}: #{account.currency} #{latest_balance.to_i}"
    end

    # Calculate net worth properly: assets - liabilities (liabilities are positive debt amounts)
    total_assets = family.accounts.asset.reload.sum { |a| a.balances.order(:date).last&.balance || 0 }
    total_liabilities = family.accounts.liability.reload.sum { |a| a.balances.order(:date).last&.balance || 0 }
    net_worth = total_assets - total_liabilities # Subtract liabilities (debt) from assets

    puts "\n💰 Assets: $#{total_assets.to_i}"
    puts "💳 Liabilities: $#{total_liabilities.to_i}"
    puts "🏦 Net Worth: $#{net_worth.to_i} #{net_worth > 0 ? '✅' : '❌'}"
    puts "📊 Total Transactions: #{Entry.joins(:account).where(accounts: { family_id: family.id }).count}"
  end
end
