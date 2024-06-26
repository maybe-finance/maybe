module Account::Entryable
  extend ActiveSupport::Concern

  included do
    has_one :entry, as: :entryable, touch: true

    delegate :name, to: :entry
    delegate :date, to: :entry
    delegate :amount, to: :entry
    delegate :amount_money, to: :entry
    delegate :currency, to: :entry

    scope :with_entry, -> { includes(:entry) }
    scope :ordered_with_entry, -> { joins(:entry).order("account_entries.date DESC, account_entries.id ASC") }

    default_scope -> { with_entry }
  end
end
