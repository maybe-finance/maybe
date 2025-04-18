require "test_helper"

module ImportInterfaceTest
  extend ActiveSupport::Testing::Declarative

  test "import interface" do
    assert_respond_to @subject, :publish
    assert_respond_to @subject, :publish_later
    assert_respond_to @subject, :generate_rows_from_csv
    assert_respond_to @subject, :csv_rows
    assert_respond_to @subject, :csv_headers
    assert_respond_to @subject, :csv_sample
    assert_respond_to @subject, :uploaded?
    assert_respond_to @subject, :configured?
    assert_respond_to @subject, :cleaned?
    assert_respond_to @subject, :publishable?
    assert_respond_to @subject, :importing?
    assert_respond_to @subject, :complete?
    assert_respond_to @subject, :failed?
  end

  test "publishes later" do
    import = imports(:transaction)

    import.stubs(:publishable?).returns(true)

    assert_enqueued_with job: ImportJob, args: [ import ] do
      import.publish_later
    end

    assert_equal "importing", import.reload.status
  end

  test "raises if not publishable" do
    import = imports(:transaction)

    import.stubs(:publishable?).returns(false)

    assert_raises(RuntimeError, "Import is not publishable") do
      import.publish_later
    end
  end

  test "handles publish errors" do
    import = imports(:transaction)

    import.stubs(:publishable?).returns(true)
    import.stubs(:import!).raises(StandardError, "Failed to publish")

    assert_nil import.error

    import.publish

    assert_equal "Failed to publish", import.error
    assert_equal "failed", import.status
  end

  test "parses US/UK number format correctly" do
    import = imports(:transaction)
    import.update!(
      number_format: "1,234.56",
      amount_col_label: "amount",
      date_col_label: "date",
      name_col_label: "name",
      date_format: "%m/%d/%Y"
    )

    csv_data = "date,amount,name\n01/01/2024,\"1,234.56\",Test"
    import.update!(raw_file_str: csv_data)
    import.generate_rows_from_csv
    import.reload
    row = import.rows.first
    assert_equal "1234.56", row.amount
  end

  test "parses European number format correctly" do
    import = imports(:transaction)
    import.update!(
      number_format: "1.234,56",
      amount_col_label: "amount",
      date_col_label: "date",
      name_col_label: "name",
      date_format: "%m/%d/%Y"
    )

    csv_data = "date,amount,name\n01/01/2024,\"1.234,56\",Test"
    import.update!(raw_file_str: csv_data)
    import.generate_rows_from_csv
    import.reload

    row = import.rows.first
    assert_equal "1234.56", row.amount
  end

  test "parses French/Scandinavian number format correctly" do
    import = imports(:transaction)
    import.update!(
      number_format: "1 234,56",
      amount_col_label: "amount",
      date_col_label: "date",
      name_col_label: "name",
      date_format: "%m/%d/%Y"
    )

    # Quote the amount field to ensure proper CSV parsing
    csv_data = "date,amount,name\n01/01/2024,\"1 234,56\",Test"
    import.update!(raw_file_str: csv_data)
    import.generate_rows_from_csv
    import.reload

    row = import.rows.first
    assert_equal "1234.56", row.amount
  end

  test "parses zero-decimal currency format correctly" do
    import = imports(:transaction)
    import.update!(
      number_format: "1,234",
      amount_col_label: "amount",
      date_col_label: "date",
      name_col_label: "name",
      date_format: "%m/%d/%Y"
    )

    csv_data = "date,amount,name\n01/01/2024,1234,Test"
    import.update!(raw_file_str: csv_data)
    import.generate_rows_from_csv
    import.reload

    row = import.rows.first
    assert_equal "1234", row.amount
  end

  test "currency from CSV takes precedence over default" do
    import = imports(:transaction)
    import.update!(
      amount_col_label: "amount",
      date_col_label: "date",
      name_col_label: "name",
      currency_col_label: "currency",
      number_format: "1,234.56",
      date_format: "%m/%d/%Y"
    )
    import.family.update!(currency: "USD")

    csv_data = "date,amount,name,currency\n01/01/2024,123.45,Test,EUR"
    import.update!(raw_file_str: csv_data)
    import.generate_rows_from_csv
    import.reload

    row = import.rows.first
    assert_equal "EUR", row.currency
  end

  test "uses default currency when CSV currency column is empty" do
    import = imports(:transaction)
    import.update!(
      amount_col_label: "amount",
      date_col_label: "date",
      name_col_label: "name",
      currency_col_label: "currency",
      number_format: "1,234.56",
      date_format: "%m/%d/%Y"
    )
    import.family.update!(currency: "USD")

    csv_data = "date,amount,name,currency\n01/01/2024,123.45,Test,"
    import.update!(raw_file_str: csv_data)
    import.generate_rows_from_csv
    import.reload

    row = import.rows.first
    assert_equal "USD", row.currency
  end

  test "uses default currency when CSV has no currency column" do
    import = imports(:transaction)
    import.update!(
      amount_col_label: "amount",
      date_col_label: "date",
      name_col_label: "name",
      number_format: "1,234.56",
      date_format: "%m/%d/%Y"
    )
    import.family.update!(currency: "USD")

    csv_data = "date,amount,name\n01/01/2024,123.45,Test"
    import.update!(raw_file_str: csv_data)
    import.generate_rows_from_csv
    import.reload

    row = import.rows.first
    assert_equal "USD", row.currency
  end

  test "generates rows with all optional fields" do
    import = imports(:transaction)
    import.update!(
      amount_col_label: "amount",
      date_col_label: "date",
      name_col_label: "name",
      account_col_label: "account",
      category_col_label: "category",
      tags_col_label: "tags",
      notes_col_label: "notes",
      currency_col_label: "currency",
      number_format: "1,234.56",
      date_format: "%m/%d/%Y"
    )

    csv_data = "date,amount,name,account,category,tags,notes,currency\n" \
               "01/01/2024,1234.56,Salary,Bank Account,Income,\"monthly,salary\",Salary payment,EUR"
    import.update!(raw_file_str: csv_data)
    import.generate_rows_from_csv
    import.reload

    row = import.rows.first
    assert_equal "01/01/2024", row.date
    assert_equal "1234.56", row.amount
    assert_equal "Salary", row.name
    assert_equal "Bank Account", row.account
    assert_equal "Income", row.category
    assert_equal "monthly,salary", row.tags
    assert_equal "Salary payment", row.notes
    assert_equal "EUR", row.currency
  end

  test "generates rows with minimal required fields" do
    import = imports(:transaction)
    import.update!(
      amount_col_label: "amount",
      date_col_label: "date",
      number_format: "1,234.56",
      date_format: "%m/%d/%Y"
    )

    csv_data = "date,amount\n01/01/2024,1234.56"
    import.update!(raw_file_str: csv_data)
    import.generate_rows_from_csv
    import.reload

    row = import.rows.first
    assert_equal "01/01/2024", row.date
    assert_equal "1234.56", row.amount
    assert_equal "Imported item", row.name # Default name
    assert_equal import.family.currency, row.currency # Default currency
  end

  test "handles empty values in optional fields" do
    import = imports(:transaction)
    import.update!(
      amount_col_label: "amount",
      date_col_label: "date",
      name_col_label: "name",
      category_col_label: "category",
      tags_col_label: "tags",
      number_format: "1,234.56",
      date_format: "%m/%d/%Y"
    )

    csv_data = "date,amount,name,category,tags\n01/01/2024,1234.56,,,"
    import.update!(raw_file_str: csv_data)
    import.generate_rows_from_csv
    import.reload

    row = import.rows.first
    assert_equal "01/01/2024", row.date
    assert_equal "1234.56", row.amount
    assert_equal "Imported item", row.name # Falls back to default
    assert_equal "", row.category
    assert_equal "", row.tags
  end

  test "can submit configuration that results in invalid rows for user to fix later" do
    import = imports(:transaction)

    csv_data = "date,amount,name\n01/01/2024,1234.56,Test"
    import.update!(raw_file_str: csv_data)
    import.update!(
      date_col_label: "date",
      date_format: "%Y-%m-%d" # Does not match the raw CSV date, so rows will be invalid, but still generated
    )

    import.generate_rows_from_csv
    import.reload

    assert_equal "01/01/2024", import.rows.first.date
    assert import.rows.first.invalid?
  end

  test "handles trade-specific fields" do
    import = imports(:transaction)
    import.update!(
      amount_col_label: "amount",
      date_col_label: "date",
      qty_col_label: "quantity",
      ticker_col_label: "symbol",
      price_col_label: "price",
      number_format: "1,234.56",
      date_format: "%m/%d/%Y"
    )

    csv_data = "date,amount,quantity,symbol,price\n01/01/2024,1234.56,10,AAPL,123.456"
    import.update!(raw_file_str: csv_data)
    import.generate_rows_from_csv
    import.reload

    row = import.rows.first
    assert_equal "10", row.qty
    assert_equal "AAPL", row.ticker
    assert_equal "123.456", row.price
  end
end
