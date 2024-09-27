class MintImport < Import
  after_create :set_mappings

  def import!
    transaction do
      rows.each do |row|
        account = family.accounts.find_by(name: row[:account]) || mappings.of_type(Import::AccountMapping).find_by(key: row[:account])&.account

        account.import = self if account.new_record?
        account.save! if account.new_record?

        category = family.categories.find_by(name: row[:category]) || mappings.of_type(Import::CategoryMapping).find_by(key: row[:category])&.category

        tag_keys = row[:tags]&.split("|") || []
        tags = tag_keys.map { |key| family.tags.find_by(name: key) || mappings.of_type(Import::TagMapping).find_by(key: key)&.tag }.compact

        entry = account.entries.build \
          date: normalize_date_str(row[:date]),
          amount: row[:amount].to_d,
          name: row[:name] || "Imported transaction",
          currency: account.currency,
          entryable: Account::Transaction.new(category: category, tags: tags, notes: row[:notes]),
          import: self

        entry.save!
      end

      self.status = :complete
      save!
    end
  end


  def mapping_steps
    [ Import::CategoryMapping, Import::TagMapping, Import::AccountMapping ]
  end

  def csv_template
    template = <<-CSV
      Date,Amount,Account Name,Description,Category,Labels,Currency,Notes,Transaction Type
      01/01/2024,-8.55,Checking,Starbucks,Food & Drink,Coffee|Breakfast,USD,Morning coffee,debit
      04/15/2024,2000,Savings,Paycheck,Income,,USD,Bi-weekly salary,credit
    CSV

    CSV.parse(template, headers: true)
  end

  private
    def set_mappings
      self.date_col_label = "Date"
      self.date_format = "%m/%d/%Y"
      self.name_col_label = "Description"
      self.amount_col_label = "Amount"
      self.currency_col_label = "Currency"
      self.account_col_label = "Account Name"
      self.category_col_label = "Category"
      self.tags_col_label = "Labels"
      self.notes_col_label = "Notes"
      self.entity_type_col_label = "Transaction Type"

      save!
    end
end
