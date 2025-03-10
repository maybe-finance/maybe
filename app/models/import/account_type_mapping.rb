class Import::AccountTypeMapping < Import::Mapping
  validates :value, presence: true

  class << self
    def mappables_by_key(import)
      import.rows.map(&:entity_type).uniq.index_with { nil }
    end
  end

  def selectable_values
    Accountable::TYPES.map { |type| [ type.titleize, type ] }
  end

  def requires_selection?
    true
  end

  def values_count
    import.rows.where(entity_type: key).count
  end

  def create_mappable!
    # no-op
  end
end
