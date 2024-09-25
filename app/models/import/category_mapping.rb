class Import::CategoryMapping < Import::Mapping
  def category
    mappable.nil? && create_when_empty ? family.categories.new(name: key) : mappable
  end

  private
    def family
      import.family
    end
end
