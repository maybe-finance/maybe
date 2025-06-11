class Demo::TransferGenerator
  include Demo::DataHelper

  def initialize
  end

  def create_transfer_transactions!(family, count: 1)
    accounts_by_type = group_accounts_by_type(family)
    created_transfers = []

    count.times do |i|
      suffix = count > 1 ? "_#{i + 1}" : ""

      created_transfers.concat(create_credit_card_payments!(accounts_by_type, suffix: suffix))
      created_transfers.concat(create_investment_contributions!(accounts_by_type, suffix: suffix))
      created_transfers.concat(create_savings_transfers!(accounts_by_type, suffix: suffix))
      created_transfers.concat(create_loan_payments!(accounts_by_type, suffix: suffix))
    end

    created_transfers
  end

  def create_transfer!(from_account:, to_account:, amount:, date:, description: "")
    transfer = Transfer.from_accounts(
      from_account: from_account,
      to_account: to_account,
      date: date,
      amount: amount
    )

    transfer.inflow_transaction.entry.update!(
      name: "#{description.presence || 'Transfer'} from #{from_account.name}"
    )
    transfer.outflow_transaction.entry.update!(
      name: "#{description.presence || 'Transfer'} to #{to_account.name}"
    )

    transfer.status = "confirmed"
    transfer.save!

    transfer
  end

  private

    def create_credit_card_payments!(accounts_by_type, suffix: "")
      checking_accounts = accounts_by_type[:checking]
      credit_cards = accounts_by_type[:credit_cards]
      transfers = []

      return transfers unless checking_accounts.any? && credit_cards.any?

      checking = checking_accounts.first

      credit_cards.each_with_index do |credit_card, index|
        payment_amount = [ credit_card.balance.abs * 0.3, 500 ].max
        payment_date = (7 + index * 3).days.ago.to_date

        transfer = create_transfer!(
          from_account: checking,
          to_account: credit_card,
          amount: payment_amount,
          date: payment_date,
          description: "Credit card payment#{suffix}"
        )
        transfers << transfer
      end

      transfers
    end

    def create_investment_contributions!(accounts_by_type, suffix: "")
      checking_accounts = accounts_by_type[:checking]
      investment_accounts = accounts_by_type[:investments]
      transfers = []

      return transfers unless checking_accounts.any? && investment_accounts.any?

      checking = checking_accounts.first

      investment_accounts.each_with_index do |investment, index|
        contribution_amount = case investment.name
        when /401k/i then 1500
        when /Roth/i then 500
        else 1000
        end

        contribution_date = (14 + index * 7).days.ago.to_date

        transfer = create_transfer!(
          from_account: checking,
          to_account: investment,
          amount: contribution_amount,
          date: contribution_date,
          description: "Investment contribution#{suffix}"
        )
        transfers << transfer
      end

      transfers
    end

    def create_savings_transfers!(accounts_by_type, suffix: "")
      checking_accounts = accounts_by_type[:checking]
      savings_accounts = accounts_by_type[:savings]
      transfers = []

      return transfers unless checking_accounts.any? && savings_accounts.any?

      checking = checking_accounts.first

      savings_accounts.each_with_index do |savings, index|
        transfer_amount = 1000
        transfer_date = (21 + index * 5).days.ago.to_date

        transfer = create_transfer!(
          from_account: checking,
          to_account: savings,
          amount: transfer_amount,
          date: transfer_date,
          description: "Savings transfer#{suffix}"
        )
        transfers << transfer
      end

      transfers
    end

    def create_loan_payments!(accounts_by_type, suffix: "")
      checking_accounts = accounts_by_type[:checking]
      loans = accounts_by_type[:loans]
      transfers = []

      return transfers unless checking_accounts.any? && loans.any?

      checking = checking_accounts.first

      loans.each_with_index do |loan, index|
        payment_amount = case loan.name
        when /Mortgage/i then 2500
        when /Auto/i, /Car/i then 450
        else 500
        end

        payment_date = (28 + index * 2).days.ago.to_date

        transfer = create_transfer!(
          from_account: checking,
          to_account: loan,
          amount: payment_amount,
          date: payment_date,
          description: "Loan payment#{suffix}"
        )
        transfers << transfer
      end

      transfers
    end
end
