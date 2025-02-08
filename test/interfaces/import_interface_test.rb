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

    row = import.rows.first
    assert_equal "USD", row.currency
  end
end
