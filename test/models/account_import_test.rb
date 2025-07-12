require "test_helper"

class AccountImportTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper, ImportInterfaceTest

  setup do
    @subject = @import = imports(:account)
  end

  test "import creates accounts with valuations" do
    import_csv = <<~CSV
      type,name,amount,currency
      depository,Main Checking,1000.00,USD
      depository,Savings Account,5000.00,USD
    CSV

    @import.update!(
      raw_file_str: import_csv,
      entity_type_col_label: "type",
      name_col_label: "name",
      amount_col_label: "amount",
      currency_col_label: "currency"
    )

    @import.generate_rows_from_csv

    # Create mappings for account types
    @import.mappings.create! key: "depository", value: "Depository", type: "Import::AccountTypeMapping"

    @import.reload

    # Store initial counts
    initial_account_count = Account.count
    initial_entry_count = Entry.count
    initial_valuation_count = Valuation.count

    # Perform the import
    @import.publish

    # Check if import succeeded
    if @import.failed?
      fail "Import failed with error: #{@import.error}"
    end

    assert_equal "complete", @import.status

    # Check the differences
    assert_equal initial_account_count + 2, Account.count, "Expected 2 new accounts"
    assert_equal initial_entry_count + 2, Entry.count, "Expected 2 new entries"
    assert_equal initial_valuation_count + 2, Valuation.count, "Expected 2 new valuations"

    # Verify accounts were created correctly
    accounts = @import.accounts.order(:name)
    assert_equal [ "Main Checking", "Savings Account" ], accounts.pluck(:name)
    assert_equal [ 1000.00, 5000.00 ], accounts.map { |a| a.balance.to_f }

    # Verify valuations were created with correct fields
    accounts.each do |account|
      valuation = account.valuations.last
      assert_not_nil valuation
      assert_equal "opening_anchor", valuation.kind
      assert_equal account.balance, valuation.entry.amount
    end
  end

  test "column_keys returns expected keys" do
    assert_equal %i[entity_type name amount currency], @import.column_keys
  end

  test "required_column_keys returns expected keys" do
    assert_equal %i[name amount], @import.required_column_keys
  end

  test "mapping_steps returns account type mapping" do
    assert_equal [ Import::AccountTypeMapping ], @import.mapping_steps
  end

  test "dry_run returns expected counts" do
    @import.rows.create!(
      entity_type: "depository",
      name: "Test Account",
      amount: "1000.00",
      currency: "USD"
    )

    assert_equal({ accounts: 1 }, @import.dry_run)
  end

  test "max_row_count is limited to 50" do
    assert_equal 50, @import.max_row_count
  end
end
