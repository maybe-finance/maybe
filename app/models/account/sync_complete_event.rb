class Account::SyncCompleteEvent
  attr_reader :account

  Error = Class.new(StandardError)

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

    # Replace the groups this account belongs to in both desktop and mobile sidebars
    sidebar_targets.each do |(tab, mobile_flag)|
      account.broadcast_replace_to(
        account.family,
        target: account_group.dom_id(tab: tab, mobile: mobile_flag),
        partial: "accounts/accountable_group",
        locals: { account_group: account_group, open: true, all_tab: tab == :all, mobile: mobile_flag }
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
    # Returns an array of [tab, mobile?] tuples that should receive an update.
    # We broadcast to both the classification-specific tab and the "all" tab,
    # for desktop (mobile: false) and mobile (mobile: true) variants.
    def sidebar_targets
      return [] unless account_group.present?

      [
        [ account_group.classification.to_sym, false ],
        [ :all, false ],
        [ account_group.classification.to_sym, true ],
        [ :all, true ]
      ]
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
