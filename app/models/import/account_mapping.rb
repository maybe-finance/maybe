class Import::AccountMapping < Import::Mapping
  class << self
    def sync_rows(rows)
      accounts = rows.map(&:account).reject(&:blank?).uniq

      accounts.each do |account|
        find_or_create_by(key: account)
      end
    end
  end

  def selectable_values
    import.family.accounts.alphabetically.map { |account| [ account.name, account.id ] }
  end

  def requires_selection?
    true
  end

  def values_count
    import.rows.where(account: key).count
  end

  def mappable_class
    Account
  end

  def create_mappable!
    import.family.accounts.create!(name: key, balance: 0, currency: import.family.currency, accountable: Depository.new, import: import)
  end
end
