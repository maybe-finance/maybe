class TransactionImport < Import
  def generate_rows_from_csv
    rows.destroy_all

    mapped_rows = csv_rows.map do |row|
      {
        type: "Import::TransactionRow",
        account: row[account_col_label] || "Default Import Account",
        date: row[date_col_label],
        amount: row[amount_col_label],
        currency: row[currency_col_label] || family.currency,
        name: row[name_col_label] || "Imported transaction",
        category: row[category_col_label] || "Uncategorized",
        tags: row[tags_col_label] || "Untagged",
        notes: row[notes_col_label]
      }
    end

    rows.insert_all!(mapped_rows)
  end

  def publish
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
    %w[categories tags accounts]
  end

  def csv_tags
    rows.map(&:tags).uniq.compact.flat_map do |tags|
      tags.split("|").reject(&:blank?)
    end.uniq.sort
  end

  def csv_categories
    rows.map(&:category).reject(&:blank?).uniq.sort
  end

  def csv_accounts
    rows.map(&:account).reject(&:blank?).uniq.sort
  end

  def csv_valid?
    rows.any? && rows.map(&:valid?).all?
  end

  def configured?
    uploaded? && rows.any?
  end

  def publishable?
    cleaned?
  end

  def csv_template
    template = <<-CSV
      Date*,Amount*,Account,Name,Category,Tags
      2024-01-01,-8.55,Checking,Starbucks,Food & Drink,Tag1|Tag2
      2024-04-15,2000,Savings,Paycheck,Income,
    CSV

    CSV.parse(template, headers: true)
  end
end
