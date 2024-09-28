class Import::AccountTypeMapping < Import::Mapping
  validates :value, presence: true

  class << self
    def mapping_values(import)
      import.rows.map(&:entity_type).uniq
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
