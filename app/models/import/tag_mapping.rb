class Import::TagMapping < Import::Mapping
  def tag
    mappable.nil? && create_when_empty ? family.tags.new(name: key) : mappable
  end

  private
    def family
      import.family
    end
end
