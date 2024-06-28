class Account::Entry < ApplicationRecord
  TYPES = %w[ Account::Valuation Account::Transaction ]

  include Monetizable

  monetize :amount

  belongs_to :account

  delegated_type :entryable, types: TYPES, dependent: :destroy
  accepts_nested_attributes_for :entryable

  validates :date, :amount, :currency, presence: true
  validates :date, uniqueness: { scope: :account_id }, if: -> { account_valuation? }

  scope :chronological, -> { order(:date, :created_at) }
  scope :reverse_chronological, -> { order(date: :desc, created_at: :desc) }

  def sync_account_later
    if destroyed?
      sync_start_date = previous_entry&.date
    else
      sync_start_date = [ date_previously_was, date ].compact.min
    end

    account.sync_later(sync_start_date)
  end

  def entryable_name_short
    entryable_name.gsub(/^account_/, "")
  end

  class << self
    def income_total(currency = "USD")
      account_transactions.includes(:entryable)
                          .where("account_entries.amount <= 0")
                          .where("account_entries.currency = ?", currency)
                          .reject { |e| e.account_transaction.transfer? }
                          .sum(&:amount_money)
    end

    def expense_total(currency = "USD")
      account_transactions.includes(:entryable)
                          .where("account_entries.amount > 0")
                          .where("account_entries.currency = ?", currency)
                          .reject { |e| e.account_transaction.transfer? }
                          .sum(&:amount_money)
    end

    def search(params)
      query = all
      query = query.where("account_entries.name ILIKE ?", "%#{params[:search]}%") if params[:search].present?
      query = query.where("account_entries.date >= ?", params[:start_date]) if params[:start_date].present?
      query = query.where("account_entries.date <= ?", params[:end_date]) if params[:end_date].present?

      if params[:accounts].present? || params[:account_ids].present?
        query = query.joins(:account)
      end

      query = query.where(accounts: { name: params[:accounts] }) if params[:accounts].present?
      query = query.where(accounts: { id: params[:account_ids] }) if params[:account_ids].present?

      # Search attributes on each entryable to further refine results
      entryable_ids = entryable_search(params)
      if entryable_ids.present?
        query.where(entryable_id: entryable_ids)
      else
        query
      end
    end

    private

      def entryable_search(params)
        entryable_ids = []
        entryable_search_performed = false

        TYPES.map(&:constantize).each do |entryable|
          next unless entryable.requires_search?(params)

          entryable_search_performed = true
          entryable_ids += entryable.search(params).pluck(:id)
        end

        return nil unless entryable_search_performed

        entryable_ids
      end
  end

  private

    def previous_entry
      @previous_entry ||= account
                            .entries
                            .where("date < ?", date)
                            .order(date: :desc)
                            .first
    end
end
