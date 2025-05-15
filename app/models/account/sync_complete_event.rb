class Account::SyncCompleteEvent
  attr_reader :account

  def initialize(account)
    @account = account
  end

  def broadcast
    # Replace account row in accounts list
    account.broadcast_replace_to(
      account.family,
      target: "account_#{account.id}",
      partial: "accounts/account",
      locals: { account: account }
    )

    # Replace the groups this account belongs to in the sidebar
    account_group_ids.each do |id|
      account.broadcast_replace_to(
        account.family,
        target: id,
        partial: "accounts/accountable_group",
        locals: { account_group: account_group, open: true }
      )
    end

    # If this is a manual, unlinked account (i.e. not part of a Plaid Item),
    # trigger the family sync complete broadcast so net worth graph is updated
    unless account.linked?
      account.family.broadcast_sync_complete
    end

    # Refresh entire account page (only applies if currently viewing this account)
    account.broadcast_refresh
  end

  private
    # The sidebar will show the account in both its classification tab and the "all" tab,
    # so we need to broadcast to both.
    def account_group_ids
      return [] unless account_group.present?

      id = account_group.id
      [ id, "#{account_group.classification}_#{id}" ]
    end

    def account_group
      family_balance_sheet.account_groups.find do |group|
        group.accounts.any? { |a| a.id == account.id }
      end
    end

    def family_balance_sheet
      account.family.balance_sheet
    end
end
