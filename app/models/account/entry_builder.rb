class Account::EntryBuilder
  include ActiveModel::Model

  TYPES = %w[income expense buy sell interest transfer_in transfer_out].freeze

  attr_accessor :type, :date, :qty, :ticker, :price, :amount, :currency, :account, :transfer_account_id

  validates :type, inclusion: { in: TYPES }

  def save
    if valid?
      create_builder.save
    end
  end

  private

    def create_builder
      case type
      when "buy", "sell"
        create_trade_builder
      else
        create_transaction_builder
      end
    end

    def create_trade_builder
      Account::TradeBuilder.new \
        type: type,
        date: date,
        qty: qty,
        ticker: ticker,
        price: price,
        account: account
    end

    def create_transaction_builder
      Account::TransactionBuilder.new \
        type: type,
        date: date,
        amount: amount,
        account: account,
        transfer_account_id: transfer_account_id
    end
end
