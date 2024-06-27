class Account::Entry < ApplicationRecord
  include Monetizable

  monetize :amount

  belongs_to :account

  delegated_type :entryable, types: %w[ Account::Valuation Account::Transaction ], dependent: :destroy
  accepts_nested_attributes_for :entryable

  validates :date, :amount, :currency, presence: true
  validates :date, uniqueness: { scope: :account_id }, if: -> { account_valuation? }

  scope :chronological, -> { order(:date) }
  scope :reverse_chronological, -> { order(date: :desc) }

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

  private

    def previous_entry
      @previous_entry ||= account
                            .entries
                            .where("date < ?", date)
                            .order(date: :desc)
                            .first
    end
end
