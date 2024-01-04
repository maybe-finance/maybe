class GenerateBalanceJob
  include Sidekiq::Job

  def perform(account_id)
    account = Account.find(account_id)

    return if account.nil?

    # Calculate change since last balance
    last_balance = Balance.where(account_id: account_id, security_id: nil).order(date: :desc).limit(2).last&.balance

    # Get current balance and save it to Balance model. Update based on account and date. Don't add last_balance if it's nil.
    Balance.find_or_initialize_by(account_id: account_id, security_id: nil, date: Date.today, kind: 'account', family_id: account.family.id).update(balance: account.current_balance, change: last_balance.nil? ? 0 : account.current_balance - last_balance)
    
    # Check if there holdings
    if account.holdings.any?
      # Get current holdings value and save it to Balance model. Update based on account, security and date.
      account.holdings.each do |holding|
        last_holding_balance = Balance.where(account_id: account_id, security_id: holding.security_id).order(date: :desc).limit(2).last&.balance

        Balance.find_or_initialize_by(account_id: account_id, security_id: holding.security_id, date: Date.today, kind: 'security', family_id: account.family.id).update(balance: holding.value, cost_basis: holding.cost_basis_source, quantity: holding.quantity, change: last_holding_balance.nil? ? 0 : holding.value - last_holding_balance)
      end
    end
  end
end
