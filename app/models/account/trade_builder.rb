class Account::TradeBuilder
  include ActiveModel::Model

  attr_accessor :account, :date, :amount, :currency, :qty,
                :price, :ticker, :type, :transfer_account_id

  def save
    buildable.save
  end

  def errors
    buildable.errors
  end

  def sync_account_later
    buildable.sync_account_later
  end

  private
    def buildable
      case type
      when "buy", "sell"
        build_trade
      when "deposit", "withdrawal"
        build_transfer
      when "interest"
        build_interest
      else
        raise "Unknown trade type: #{type}"
      end
    end

    def build_trade
      account.entries.new(
        date: date,
        amount: signed_amount,
        currency: currency,
        entryable: Account::Trade.new(
          qty: signed_qty,
          price: price,
          currency: currency,
          security: security
        )
      )
    end

    def build_transfer
      transfer_account = family.accounts.find(transfer_account_id) if transfer_account_id.present?

      if transfer_account
        from_account = type == "withdrawal" ? account : transfer_account
        to_account = type == "withdrawal" ? transfer_account : account

        Account::Transfer.build_from_accounts(
          from_account,
          to_account,
          date: date,
          amount: signed_amount
        )
      else
        account.entries.build(
          name: signed_amount < 0 ? "Deposit to #{account.name}" : "Withdrawal from #{account.name}",
          date: date,
          amount: signed_amount,
          currency: currency,
          marked_as_transfer: true,
          entryable: Account::Transaction.new
        )
      end
    end

    def build_interest
      account.entries.build(
        name: "Interest payment",
        date: date,
        amount: signed_amount,
        currency: currency,
        entryable: Account::Transaction.new
      )
    end

    def signed_qty
      return nil unless type.in?([ "buy", "sell" ])

      type == "sell" ? -qty.to_d : qty.to_d
    end

    def signed_amount
      case type
      when "buy", "sell"
        signed_qty * price.to_d
      when "deposit", "withdrawal"
        type == "deposit" ? -amount.to_d : amount.to_d
      when "interest"
        amount.to_d * -1
      end
    end

    def family
      account.family
    end

    def security
      ticker_symbol, exchange_mic, exchange_acronym, exchange_country_code = ticker.split("|")

      security = Security.find_or_create_by(ticker: ticker_symbol, exchange_mic: exchange_mic, country_code: exchange_country_code)
      security.update(exchange_acronym: exchange_acronym)

      FetchSecurityInfoJob.perform_later(security.id)

      security
    end
end
