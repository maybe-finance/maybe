class Import::AccountTypeMapping < Import::Mapping
  class << self
    def sync_rows(rows)
      account_types = rows.map(&:entity_type).reject(&:blank?).uniq

      account_types.each do |account_type|
        find_or_create_by(key: account_type)
      end
    end
  end

  def selectable_values
    Accountable::TYPES.map { |type| [ type.titleize, type ] }
  end

  def requires_selection?
    true
  end

  def values_count
    import.rows.where(account_type: key).count
  end

  def create_mappable!
    Accountable.from_type(value).create! balance: 0, currency: import.family.currency, name: key
  end
end
