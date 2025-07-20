class PlaidAccount::Processor
  include PlaidAccount::TypeMappable

  attr_reader :plaid_account

  def initialize(plaid_account)
    @plaid_account = plaid_account
  end

  # Each step represents a different Plaid API endpoint / "product"
  #
  # Processing the account is the first step and if it fails, we halt the entire processor
  # Each subsequent step can fail independently, but we continue processing the rest of the steps
  def process
    process_account!
    process_transactions
    process_investments
    process_liabilities
  end

  private
    def family
      plaid_account.plaid_item.family
    end

    # Shared securities reader and resolver
    def security_resolver
      @security_resolver ||= PlaidAccount::Investments::SecurityResolver.new(plaid_account)
    end

    def process_account!
      PlaidAccount.transaction do
        account = family.accounts.find_or_initialize_by(
          plaid_account_id: plaid_account.id
        )

        # Name and subtype are the only attributes a user can override for Plaid accounts
        account.enrich_attributes(
          {
            name: plaid_account.name,
            subtype: map_subtype(plaid_account.plaid_type, plaid_account.plaid_subtype)
          },
          source: "plaid"
        )

        account.assign_attributes(
          accountable: map_accountable(plaid_account.plaid_type),
          balance: balance_calculator.balance,
          currency: plaid_account.currency,
          cash_balance: balance_calculator.cash_balance
        )

        account.save!

        # Create or update the current balance anchor valuation for event-sourced ledger
        # Note: This is a partial implementation. In the future, we'll introduce HoldingValuation
        # to properly track the holdings vs. cash breakdown, but for now we're only tracking
        # the total balance in the current anchor. The cash_balance field on the account model
        # is still being used for the breakdown.
        account.set_current_balance(balance_calculator.balance)
      end
    end

    def process_transactions
      PlaidAccount::Transactions::Processor.new(plaid_account).process
    rescue => e
      report_exception(e)
    end

    def process_investments
      PlaidAccount::Investments::TransactionsProcessor.new(plaid_account, security_resolver: security_resolver).process
      PlaidAccount::Investments::HoldingsProcessor.new(plaid_account, security_resolver: security_resolver).process
    rescue => e
      report_exception(e)
    end

    def process_liabilities
      case [ plaid_account.plaid_type, plaid_account.plaid_subtype ]
      when [ "credit", "credit card" ]
        PlaidAccount::Liabilities::CreditProcessor.new(plaid_account).process
      when [ "loan", "mortgage" ]
        PlaidAccount::Liabilities::MortgageProcessor.new(plaid_account).process
      when [ "loan", "student" ]
        PlaidAccount::Liabilities::StudentLoanProcessor.new(plaid_account).process
      end
    rescue => e
      report_exception(e)
    end

    def balance_calculator
      if plaid_account.plaid_type == "investment"
        @balance_calculator ||= PlaidAccount::Investments::BalanceCalculator.new(plaid_account, security_resolver: security_resolver)
      else
        balance = plaid_account.current_balance || plaid_account.available_balance || 0

        # We don't currently distinguish "cash" vs. "non-cash" balances for non-investment accounts.
        OpenStruct.new(
          balance: balance,
          cash_balance: balance
        )
      end
    end

    def report_exception(error)
      Sentry.capture_exception(error) do |scope|
        scope.set_tags(plaid_account_id: plaid_account.id)
      end
    end
end
