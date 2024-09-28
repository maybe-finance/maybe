class TransactionImport < Import
  def import!
    transaction do
      mappings.each(&:create_mappable!)

      rows.each do |row|
        account = mappings.accounts.mappable_for(row.account)
        category = mappings.categories.mappable_for(row.category)
        tags = row.tags_list.map { |tag| mappings.tags.mappable_for(tag) }.compact

        entry = account.entries.build \
          date: normalize_date_str(row.date),
          amount: row.amount.to_d,
          name: row.name,
          currency: account.currency,
          entryable: Account::Transaction.new(category: category, tags: tags, notes: row.notes),
          import: self

        entry.save!
      end
    end
  end

  def column_keys
    %i[date amount name currency category tags account notes]
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
