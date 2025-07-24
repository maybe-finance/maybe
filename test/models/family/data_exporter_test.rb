require "test_helper"

class Family::DataExporterTest < ActiveSupport::TestCase
  setup do
    @family = families(:dylan_family)
    @other_family = families(:empty)
    @exporter = Family::DataExporter.new(@family)

    # Create some test data for the family
    @account = @family.accounts.create!(
      name: "Test Account",
      accountable: Depository.new,
      balance: 1000,
      currency: "USD"
    )

    @category = @family.categories.create!(
      name: "Test Category",
      color: "#FF0000"
    )

    @tag = @family.tags.create!(
      name: "Test Tag",
      color: "#00FF00"
    )
  end

  test "generates a zip file with all required files" do
    zip_data = @exporter.generate_export

    assert zip_data.is_a?(StringIO)

    # Check that the zip contains all expected files
    expected_files = [ "accounts.csv", "transactions.csv", "trades.csv", "categories.csv", "all.ndjson" ]

    Zip::File.open_buffer(zip_data) do |zip|
      actual_files = zip.entries.map(&:name)
      assert_equal expected_files.sort, actual_files.sort
    end
  end

  test "generates valid CSV files" do
    zip_data = @exporter.generate_export

    Zip::File.open_buffer(zip_data) do |zip|
      # Check accounts.csv
      accounts_csv = zip.read("accounts.csv")
      assert accounts_csv.include?("id,name,type,subtype,balance,currency,created_at")

      # Check transactions.csv
      transactions_csv = zip.read("transactions.csv")
      assert transactions_csv.include?("date,account_name,amount,name,category,tags,notes,currency")

      # Check trades.csv
      trades_csv = zip.read("trades.csv")
      assert trades_csv.include?("date,account_name,ticker,quantity,price,amount,currency")

      # Check categories.csv
      categories_csv = zip.read("categories.csv")
      assert categories_csv.include?("name,color,parent_category,classification")
    end
  end

  test "generates valid NDJSON file" do
    zip_data = @exporter.generate_export

    Zip::File.open_buffer(zip_data) do |zip|
      ndjson_content = zip.read("all.ndjson")
      lines = ndjson_content.split("\n")

      lines.each do |line|
        assert_nothing_raised { JSON.parse(line) }
      end

      # Check that each line has expected structure
      first_line = JSON.parse(lines.first)
      assert first_line.key?("type")
      assert first_line.key?("data")
    end
  end

  test "only exports data from the specified family" do
    # Create data for another family that should NOT be exported
    other_account = @other_family.accounts.create!(
      name: "Other Family Account",
      accountable: Depository.new,
      balance: 5000,
      currency: "USD"
    )

    other_category = @other_family.categories.create!(
      name: "Other Family Category",
      color: "#0000FF"
    )

    zip_data = @exporter.generate_export

    Zip::File.open_buffer(zip_data) do |zip|
      # Check accounts.csv doesn't contain other family's data
      accounts_csv = zip.read("accounts.csv")
      assert accounts_csv.include?(@account.name)
      refute accounts_csv.include?(other_account.name)

      # Check categories.csv doesn't contain other family's data
      categories_csv = zip.read("categories.csv")
      assert categories_csv.include?(@category.name)
      refute categories_csv.include?(other_category.name)

      # Check NDJSON doesn't contain other family's data
      ndjson_content = zip.read("all.ndjson")
      refute ndjson_content.include?(other_account.id)
      refute ndjson_content.include?(other_category.id)
    end
  end
end
