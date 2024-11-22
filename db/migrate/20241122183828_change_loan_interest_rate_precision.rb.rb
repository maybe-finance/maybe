class ChangeLoanInterestRatePrecision < ActiveRecord::Migration[7.2]
  def change
    change_column :loans, :interest_rate, :decimal, precision: 10, scale: 3
  end
end
