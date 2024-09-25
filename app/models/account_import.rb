class AccountImport < Import
  def generate_rows_from_csv
    rows.destroy_all

    mapped_rows = csv_rows.map do |row|
      {
        type: "Import::AccountRow",
        name: row[name_col_label],
        amount: row[amount_col_label],
        currency: row[currency_col_label] || family.currency,
        entity_type: row[entity_type_col_label]
      }
    end

    rows.insert_all!(mapped_rows)
  end

  def publish
    transaction do
      rows.each do |row|
        accountable = mappings.of_type(Import::AccountTypeMapping).find_by(key: row.entity_type)&.accountable

        account = family.accounts.build(
          name: row.name,
          balance: row.amount,
          currency: row.currency,
          accountable: accountable,
          import: self
        )

        account.save!
      end

      self.status = :complete
      save!
    end
  end

  def mapping_steps
    %w[account_types]
  end

  def csv_account_types
    rows.map(&:entity_type).reject(&:blank?).uniq
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
      Date*,Qty*,Account,Name,Category,Tags
      2024-01-01,-8.55,Checking,Starbucks,Food & Drink,Tag1|Tag2
      2024-04-15,2000,Savings,Paycheck,Income,
    CSV

    CSV.parse(template, headers: true)
  end
end
