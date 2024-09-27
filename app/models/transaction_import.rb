class TransactionImport < Import
  def import!
    transaction do
      categories = Import::CategoryMapping.for_import(self).map { |mapping| mapping.find_or_create_mappable! }.compact.uniq
      tags = Import::TagMapping.for_import(self).map { |mapping| mapping.find_or_create_mappable! }.compact.uniq
      accounts = Import::AccountMapping.for_import(self).map { |mapping| mapping.find_or_create_mappable! }.compact.uniq

      rows.each do |row|
        account = accounts.find { |account| account.name == row.account }
        category = categories.find { |category| category.name == row.category }
        tags = row.tags_list.map { |tag| tags.find { |tag| tag.name == tag } }.compact

        entry = account.entries.build \
          date: normalize_date_str(row.date),
          amount: row.amount.to_d,
          name: row.name || "Imported transaction",
          currency: account.currency,
          entryable: Account::Transaction.new(category: category, tags: tags, notes: row.notes),
          import: self

        entry.save!
      end
    end
  end

  def mapping_steps
    [ Import::CategoryMapping, Import::TagMapping, Import::AccountMapping ]
  end

  def csv_template
    template = <<-CSV
      date*,amount*,name,currency,category,tags,account,notes
      05/15/2024,-45.99,Grocery Store,USD,Food,groceries|essentials,Checking Account,Monthly grocery run
      05/16/2024,1500.00,Salary,,Income,,Main Account,
      05/17/2024,-12.50,Coffee Shop,,,coffee,,
    CSV

    CSV.parse(template, headers: true)
  end
end
