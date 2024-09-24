class TransactionImport < Import
  # validates :date_format, inclusion: { in: [ "%d-%m-%Y", "%m-%d-%Y", "%Y-%m-%d", "%d/%m/%Y", "%Y/%m/%d", "%m/%d/%Y" ] }
  # validates :date_col_label, :amount_col_label, :date_format, :amount_sign_format, presence: true

  def generate_rows_from_csv
    rows.destroy_all

    mapped_rows = csv_rows.map do |row|
      {
        type: "Import::TransactionRow",
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

  def mapping_steps
    %w[categories tags]
  end

  def csv_tags
    rows.map do |row|
      row.tags&.split("|") || []
    end.flatten.compact.uniq
  end

  def csv_categories
    rows.map do |row|
      row.category
    end.flatten.compact.uniq
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
end
