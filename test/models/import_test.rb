require "test_helper"

class ImportTest < ActiveSupport::TestCase
  include ImportTestHelper, ActiveJob::TestHelper

  setup do
    @empty_import = imports(:empty_import)

    @loaded_import = @empty_import.dup
    @loaded_import.update! raw_file_str: valid_csv_str
  end

  test "validates the correct col_sep" do
    assert_equal ",", @empty_import.col_sep

    assert @empty_import.valid?

    @empty_import.col_sep = "invalid"
    assert @empty_import.invalid?

    @empty_import.col_sep = ","
    assert @empty_import.valid?

    @empty_import.col_sep = ";"
    assert @empty_import.valid?
  end

  test "raw csv input must conform to csv spec" do
    @empty_import.raw_file_str = malformed_csv_str
    assert_not @empty_import.valid?

    @empty_import.raw_file_str = valid_csv_str
    assert @empty_import.valid?
  end

  test "publishes later" do
    assert_enqueued_with(job: ImportJob) do
      @loaded_import.publish_later
    end
  end

  test "publishes a valid import" do
    # Import has 3 unique categories: "Food & Drink", "Income", and "Shopping" (x2)
    # Fixtures already define "Food & Drink" and "Income", so these should not be created
    # "Shopping" is a new category, but should only be created 1x during import
    assert_difference \
      -> { Account::Transaction.count } => 4,
      -> { Account::Entry.count } => 4,
      -> { Category.count } => 1,
      -> { Tagging.count } => 4,
      -> { Tag.count } => 2 do
      @loaded_import.publish
    end

    @loaded_import.reload

    assert @loaded_import.complete?
  end

  test "publishes a valid import with missing data" do
    @empty_import.update! raw_file_str: valid_csv_with_missing_data
    assert_difference -> { Category.count } => 1,
                      -> { Account::Transaction.count } => 2,
                      -> { Account::Entry.count } => 2 do
      @empty_import.publish
    end

    assert_not_nil Account::Entry.find_sole_by(name: Import::FALLBACK_TRANSACTION_NAME)

    @empty_import.reload

    assert @empty_import.complete?
  end

  test "failed publish results in error status" do
    @empty_import.update! raw_file_str: valid_csv_with_invalid_values

    assert_difference "Account::Transaction.count", 0 do
      @empty_import.publish
    end

    @empty_import.reload
    assert @empty_import.failed?
  end

  test "can create transactions from csv with custom column separator" do
    loaded_import = @empty_import.dup

    assert_equal 0, loaded_import.rows.count

    loaded_import.update! raw_file_str: valid_csv_str_with_semicolon_separator, col_sep: ";"

    expected_rows = [
      { import_id: loaded_import.id, index: 0, fields: { date: "2024-01-01", name: "Starbucks drink", category: "Food & Drink", tags: "Tag1|Tag2", amount: "-8.55" } },
      { import_id: loaded_import.id, index: 1, fields: { date: "2024-01-01", name: "Etsy", category: "Shopping", tags: "Tag1", amount: "-80.98" } },
      { import_id: loaded_import.id, index: 2, fields: { date: "2024-01-02", name: "Amazon stuff", category: "Shopping", tags: "Tag2", amount: "-200" } },
      { import_id: loaded_import.id, index: 3, fields: { date: "2024-01-03", name: "Paycheck", category: "Income", tags: nil, amount: "1000" } }
    ].as_json

    assert_equal expected_rows, loaded_import.rows.map { |r| r.as_json(except: [ :id, :created_at, :updated_at ]) }

    transactions = loaded_import.dry_run

    assert_equal 4, transactions.count

    data = transactions.first.as_json(only: [ :name, :amount, :date ])
    assert_equal data, { "amount" => "8.55", "date" => "2024-01-01", "name" => "Starbucks drink" }
  end
end
