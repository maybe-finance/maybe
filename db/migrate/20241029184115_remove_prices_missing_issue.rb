class RemovePricesMissingIssue < ActiveRecord::Migration[7.2]
  def up
    execute "DELETE FROM issues WHERE type = 'Issue::PricesMissing'"
  end

  def down
    # Cannot restore deleted issues since we don't have the original data
  end
end
