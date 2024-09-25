class Import::AccountMapping < Import::Mapping
  after_create :set_defaults

  def account
    mappable.nil? && create_when_empty ? create_new_account : mappable
  end

  private
    def set_defaults
      self.create_when_empty = true
      save!
    end

    def family
      import.family
      end

    def create_new_account
      if import.type == "TradeImport"
        family.accounts.new(name: key, balance: 0, currency: import.family.currency, accountable: Investment.new)
      else
        family.accounts.new(name: key, balance: 0, currency: import.family.currency, accountable: Depository.new)
      end
    end
end
