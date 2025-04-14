module Entryable
  extend ActiveSupport::Concern

  TYPES = %w[Valuation Transaction Trade]

  def self.from_type(entryable_type)
    entryable_type.presence_in(TYPES).constantize
  end

  included do
    has_one :entry, as: :entryable, touch: true

    scope :with_entry, -> { joins(:entry) }

    scope :active, -> { with_entry.merge(Entry.active) }

    scope :in_period, ->(period) {
      with_entry.where(entries: { date: period.start_date..period.end_date })
    }

    scope :reverse_chronological, -> {
      with_entry.merge(Entry.reverse_chronological)
    }

    scope :chronological, -> {
      with_entry.merge(Entry.chronological)
    }
  end
end
