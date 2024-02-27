class AccountSyncer
    def initialize(account)
      @account = account
    end

    def sync(start_date: nil)
        @account.status = "SYNCING"
        @account.save!

        sync_balances(start_date: start_date)
        purge_balances(start_date: start_date)

        @account.status = "OK"
        @account.save!
    end

    private
        def sync_balances(start_date: nil)
            puts "Mock: Syncing Balances"
        end

        def purge_balances(start_date: nil)
            puts "Mock: Purging Balances"
        end
end
