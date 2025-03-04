class Import::TagMapping < Import::Mapping
  class << self
    def mappables_by_key(import)
      unique_values = import.rows.map(&:tags_list).flatten.uniq

      tags = import.family.tags.where(name: unique_values).index_by(&:name)

      unique_values.index_with { |value| tags[value] }
    end
  end

  def selectable_values
    family_tags = import.family.tags.alphabetically.map { |tag| [ tag.name, tag.id ] }

    unless key.blank?
      family_tags.unshift [ "Add as new tag", CREATE_NEW_KEY ]
    end

    family_tags
  end

  def requires_selection?
    false
  end

  def values_count
    import.rows.map(&:tags_list).flatten.count { |tag| tag == key }
  end

  def mappable_class
    Tag
  end

  def create_mappable!
    return unless creatable?

    self.mappable = import.family.tags.find_or_create_by!(name: key)
    save!
  end
end
