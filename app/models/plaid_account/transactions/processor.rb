class PlaidAccount::Transactions::Processor
  def initialize(plaid_account)
    @plaid_account = plaid_account
  end

  def process
    PlaidAccount.transaction do
      modified_transactions.each do |transaction|
        PlaidEntry::TransactionProcessor.new(transaction, plaid_account: plaid_account).process
      end

      removed_transactions.each do |transaction|
        remove_plaid_transaction(transaction)
      end
    end
  end

  private
    attr_reader :plaid_account

    def account
      plaid_account.account
    end

    def remove_plaid_transaction(raw_transaction)
      account.entries.find_by(plaid_id: raw_transaction["transaction_id"])&.destroy
    end

    # Since we find_or_create_by transactions, we don't need a distinction between added/modified
    def modified_transactions
      modified = plaid_account.raw_transactions_payload["modified"] || []
      added = plaid_account.raw_transactions_payload["added"] || []

      modified + added
    end

    def removed_transactions
      plaid_account.raw_transactions_payload["removed"] || []
    end
end
