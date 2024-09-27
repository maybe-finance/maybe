class Import::TagMapping < Import::Mapping
  class << self
    def sync_rows(rows)
      tags = rows.map(&:tags_list).flatten.reject(&:blank?).uniq

      tags.each do |tag|
        find_or_create_by(key: tag)
      end
    end
  end

  def selectable_values
    import.family.tags.alphabetically.map { |tag| [ tag.name, tag.id ] }
  end

  def requires_selection?
    true
  end

  def values_count
    import.rows.map(&:tags_list).flatten.count { |tag| tag == key }
  end

  def mappable_class
    Tag
  end

  def create_mappable!
    import.family.tags.create!(name: key)
  end
end
