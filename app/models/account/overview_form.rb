class Account::OverviewForm
  include ActiveModel::Model

  attr_accessor :account, :name, :currency, :opening_date
  attr_reader :opening_balance, :opening_cash_balance, :current_balance, :current_cash_balance

  Result = Struct.new(:success?, :updated?, :error, keyword_init: true)
  CurrencyUpdateError = Class.new(StandardError)

  def opening_balance=(value)
    @opening_balance = value.nil? ? nil : value.to_d
  end

  def opening_cash_balance=(value)
    @opening_cash_balance = value.nil? ? nil : value.to_d
  end

  def current_balance=(value)
    @current_balance = value.nil? ? nil : value.to_d
  end

  def current_cash_balance=(value)
    @current_cash_balance = value.nil? ? nil : value.to_d
  end

  def save
    # Validate that balance fields are properly paired
    if (!opening_balance.nil? && opening_cash_balance.nil?) ||
       (opening_balance.nil? && !opening_cash_balance.nil?)
      raise ArgumentError, "Both opening_balance and opening_cash_balance must be provided together"
    end

    if (!current_balance.nil? && current_cash_balance.nil?) ||
       (current_balance.nil? && !current_cash_balance.nil?)
      raise ArgumentError, "Both current_balance and current_cash_balance must be provided together"
    end

    updated = false
    sync_required = false

    Account.transaction do
      # Update name if provided
      if name.present? && name != account.name
        account.update!(name: name)
        updated = true
      end

      # Update currency if provided
      if currency.present? && currency != account.currency
        account.update_currency!(currency)
        updated = true
        sync_required = true
      end

      # Update opening balance if provided (already validated that both are present)
      if !opening_balance.nil?
        account.set_or_update_opening_balance!(
          balance: opening_balance,
          cash_balance: opening_cash_balance,
          date: opening_date  # optional
        )
        updated = true
        sync_required = true
      end

      # Update current balance if provided (already validated that both are present)
      if !current_balance.nil?
        account.update_current_balance!(
          balance: current_balance,
          cash_balance: current_cash_balance
        )
        updated = true
        sync_required = true
      end
    end

    # Only sync if transaction succeeded and sync is required
    account.sync_later if sync_required

    Result.new(success?: true, updated?: updated)
  rescue ArgumentError => e
    # Re-raise ArgumentError as it's a developer error
    raise e
  rescue => e
    Result.new(success?: false, updated?: false, error: e.message)
  end
end
