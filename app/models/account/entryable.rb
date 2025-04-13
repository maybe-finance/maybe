module Account::Entryable
  extend ActiveSupport::Concern

  TYPES = %w[Account::Valuation Account::Transaction Account::Trade]

  def self.from_type(entryable_type)
    entryable_type.presence_in(TYPES).constantize
  end

  included do
    include Enrichable

    has_one :entry, as: :entryable, touch: true

    scope :with_entry, -> { joins(:entry) }

    scope :active, -> { with_entry.merge(Account::Entry.active) }

    scope :in_period, ->(period) {
      with_entry.where(account_entries: { date: period.start_date..period.end_date })
    }

    scope :reverse_chronological, -> {
      with_entry.merge(Account::Entry.reverse_chronological)
    }

    scope :chronological, -> {
      with_entry.merge(Account::Entry.chronological)
    }
  end
end
