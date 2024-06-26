module Account::Entryable
  extend ActiveSupport::Concern

  included do
    has_one :entry, as: :entryable, touch: true

    scope :with_entry, -> { includes(:entry) }
    scope :ordered_with_entry, -> { joins(:entry).order("account_entries.date DESC, account_entries.id ASC") }
  end
end
