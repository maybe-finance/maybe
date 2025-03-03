require "test_helper"

class Import::RowsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)

    @import = imports(:transaction)
    @row = import_rows(:one)
  end

  test "show transaction row" do
    get import_row_path(@import, @row)

    assert_row_fields(@row, [ :date, :name, :amount, :currency, :category, :tags, :account, :notes ])

    assert_response :success
  end

  test "show trade row" do
    import = @user.family.imports.create!(type: "TradeImport")
    row = import.rows.create!(date: "01/01/2024", currency: "USD", qty: 10, price: 100, ticker: "AAPL")

    get import_row_path(import, row)

    assert_row_fields(row, [ :date, :ticker, :qty, :price, :currency, :account, :name, :account ])

    assert_response :success
  end

  test "show account row" do
    import = @user.family.imports.create!(type: "AccountImport")
    row = import.rows.create!(name: "Test Account", amount: 10000, currency: "USD")

    get import_row_path(import, row)

    assert_row_fields(row, [ :entity_type, :name, :amount, :currency ])

    assert_response :success
  end

  test "show mint row" do
    import = @user.family.imports.create!(type: "MintImport")
    row = import.rows.create!(date: "01/01/2024", amount: 100, currency: "USD")

    get import_row_path(import, row)

    assert_row_fields(row, [ :date, :name, :amount, :currency, :category, :tags, :account, :notes ])

    assert_response :success
  end

  test "update" do
    patch import_row_path(@import, @row), params: {
      import_row: {
        account: "Checking Account",
        date: "2024-01-01",
        qty: nil,
        ticker: nil,
        price: nil,
        amount: 100,
        currency: "USD",
        name: "Test",
        category: "Food",
        tags: "grocery, dinner",
        entity_type: nil,
        notes: "Weekly shopping"
      }
    }

    assert_redirected_to import_row_path(@import, @row)
  end

  private
    def assert_row_fields(row, fields)
      fields.each do |field|
        assert_select "turbo-frame##{dom_id(row, field)}"
      end
    end
end
