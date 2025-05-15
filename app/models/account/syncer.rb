class Account::Syncer
  attr_reader :account

  def initialize(account)
    @account = account
  end

  def perform_sync(sync)
    Rails.logger.info("Processing balances (#{account.linked? ? 'reverse' : 'forward'})")
    sync_balances
  end

  def perform_post_sync
    account.family.auto_match_transfers!
    account.broadcast_refresh
    SyncCompleteEvent.new(account.family, accounts: [ account ]).broadcast
    account.broadcast_replace_to(
      account.family,
      target: "account_#{account.id}",
      partial: "accounts/account",
      locals: { account: account }
    )
  end

  private
    def sync_balances
      strategy = account.linked? ? :reverse : :forward
      Balance::Syncer.new(account, strategy: strategy).sync_balances
    end
end
