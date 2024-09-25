class Import::AccountMapping < Import::Mapping
  class << self 
    def find_by_key_with_fallback(key)
       mapping = find_by(key: key)


    end
  end

  def account
    mappable.nil? && create_when_empty ? family.accounts.new(name: key) : mappable
  end

  private
    def family
      import.family
    end
end
