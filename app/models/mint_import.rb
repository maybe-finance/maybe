class MintImport < Import
  after_create :set_mappings

  def generate_rows_from_csv
    rows.destroy_all

    mapped_rows = csv_rows.map do |row|
      {
        account: row[account_col_label].to_s,
        date: row[date_col_label].to_s,
        amount: signed_csv_amount(row).to_s,
        currency: (row[currency_col_label] || default_currency).to_s,
        name: (row[name_col_label] || default_row_name).to_s,
        category: row[category_col_label].to_s,
        tags: row[tags_col_label].to_s,
        notes: row[notes_col_label].to_s
      }
    end

    rows.insert_all!(mapped_rows)
  end

  def import!
    transaction do
      mappings.each(&:create_mappable!)

      rows.each do |row|
        account = mappings.accounts.mappable_for(row.account)
        category = mappings.categories.mappable_for(row.category)
        tags = row.tags_list.map { |tag| mappings.tags.mappable_for(tag) }.compact

        entry = account.entries.build \
          date: row.date_iso,
          amount: row.signed_amount,
          name: row.name,
          currency: row.currency,
          notes: row.notes,
          entryable: Account::Transaction.new(category: category, tags: tags),
          import: self

        entry.save!
      end
    end
  end

  def mapping_steps
    [ Import::CategoryMapping, Import::TagMapping, Import::AccountMapping ]
  end

  def required_column_keys
    %i[date amount]
  end

  def column_keys
    %i[date amount name currency category tags account notes]
  end

  def csv_template
    template = <<-CSV
      Date,Amount,Account Name,Description,Category,Labels,Currency,Notes,Transaction Type
      01/01/2024,-8.55,Checking,Starbucks,Food & Drink,Coffee|Breakfast,USD,Morning coffee,debit
      04/15/2024,2000,Savings,Paycheck,Income,,USD,Bi-weekly salary,credit
    CSV

    CSV.parse(template, headers: true)
  end

  def signed_csv_amount(csv_row)
    amount = csv_row[amount_col_label]
    type = csv_row["Transaction Type"]

    if type == "credit"
      amount.to_d
    else
      amount.to_d * -1
    end
  end

  private
    def set_mappings
      self.signage_convention = "inflows_positive"
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
