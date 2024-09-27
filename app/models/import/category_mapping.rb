class Import::CategoryMapping < Import::Mapping
  class << self
    def sync_rows(rows)
      categories = rows.map(&:category).reject(&:blank?).uniq

      categories.each do |category|
        find_or_create_by(key: category)
      end
    end
  end

  def selectable_values
    import.family.categories.alphabetically.map { |category| [ category.name, category.id ] }
  end

  def requires_selection?
    true
  end

  def values_count
    import.rows.where(category: key).count
  end

  def mappable_class
    Category
  end

  def create_mappable!
    import.family.categories.create!(name: key)
  end
end
