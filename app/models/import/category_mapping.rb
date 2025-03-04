class Import::CategoryMapping < Import::Mapping
  class << self
    def mappables_by_key(import)
      unique_values = import.rows.map(&:category).uniq
      categories = import.family.categories.where(name: unique_values).index_by(&:name)

      unique_values.index_with { |value| categories[value] }
    end
  end

  def selectable_values
    family_categories = import.family.categories.alphabetically.map { |category| [ category.name, category.id ] }

    unless key.blank?
      family_categories.unshift [ "Add as new category", CREATE_NEW_KEY ]
    end

    family_categories
  end

  def requires_selection?
    false
  end

  def values_count
    import.rows.where(category: key).count
  end

  def mappable_class
    Category
  end

  def create_mappable!
    return unless creatable?

    self.mappable = import.family.categories.find_or_create_by!(name: key)
    save!
  end
end
