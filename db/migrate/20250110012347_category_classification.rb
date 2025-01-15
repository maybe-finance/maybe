class CategoryClassification < ActiveRecord::Migration[7.2]
  def change
    add_column :categories, :classification, :string, null: false, default: "expense"
    add_column :categories, :lucide_icon, :string

    # Attempt to update existing user categories that are likely to be income
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE categories
          SET classification = 'income'
          WHERE lower(name) in ('income', 'incomes', 'other income', 'other incomes');
        SQL
      end
    end
  end
end
