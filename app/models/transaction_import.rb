class TransactionImport < Import
  def generate_rows_from_csv
    rows.destroy_all

    mapped_rows = csv_rows.map do |row|
      {
        type: "Import::TransactionRow",
        account: row[account_col_label],
        date: row[date_col_label],
        amount: row[amount_col_label],
        name: row[name_col_label],
        category: row[category_col_label],
        tags: row[tags_col_label],
        notes: row[notes_col_label]
      }
    end

    rows.insert_all!(mapped_rows)
  end

  def publish
    entries = []

    rows.each do |row|
      account = mappings.of_type(Import::AccountMapping).find_with_fallback(row[:account])&.account
      category = mappings.of_type(Import::CategoryMapping).find_with_fallback(row[:category])&.category

      tag_keys = row[:tags]&.split("|") || []
      tags = tag_keys.map { |key| mappings.of_type(Import::TagMapping).find_with_fallback(key)&.tag }.compact

      entry = account.entries.build \
        date: normalize_date_str(row[:date]),
        amount: row[:amount].to_d,
        name: row[:name] || "Imported transaction",
        currency: account.currency,
        entryable: Account::Transaction.new(category: category, tags: tags, notes: row[:notes]),
        import: self

      entries << entry
    end

    transaction do
      entries.each(&:save!)
    end

    self.status = :complete
    save!
  end

  def mapping_steps
    %w[categories tags accounts]
  end

  def csv_tags
    rows.map(&:tags).uniq.compact.flat_map do |tags|
      tags.split("|").reject(&:blank?)
    end.uniq
  end

  def csv_categories
    rows.map(&:category).reject(&:blank?).uniq
  end

  def csv_accounts
    rows.map(&:account).reject(&:blank?).uniq
  end

  def csv_valid?
    rows.any? && rows.map(&:valid?).all?
  end

  def configured?
    uploaded? && date_format.present? && date_col_label.present? && amount_col_label.present? && amount_sign_format.present?
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
