# frozen_string_literal: true

require "test_helper"

class Api::V1::TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:family_admin)
    @family = @user.family
    @account = @family.accounts.first
    @transaction = @family.transactions.first

    # Destroy existing active API keys to avoid validation errors
    @user.api_keys.active.destroy_all

    # Create fresh API keys instead of using fixtures to avoid parallel test conflicts (rate limiting in test)
    @api_key = ApiKey.create!(
      user: @user,
      name: "Test Read-Write Key",
      scopes: [ "read_write" ],
      display_key: "test_rw_#{SecureRandom.hex(8)}"
    )

    @read_only_api_key = ApiKey.create!(
      user: @user,
      name: "Test Read-Only Key",
      scopes: [ "read" ],
      display_key: "test_ro_#{SecureRandom.hex(8)}",
      source: "mobile"  # Use different source to allow multiple keys
    )

    # Clear any existing rate limit data
    Redis.new.del("api_rate_limit:#{@api_key.id}")
    Redis.new.del("api_rate_limit:#{@read_only_api_key.id}")
  end

  # INDEX action tests
  test "should get index with valid API key" do
    get api_v1_transactions_url, headers: api_headers(@api_key)
    assert_response :success

    response_data = JSON.parse(response.body)
    assert response_data.key?("transactions")
    assert response_data.key?("pagination")
    assert response_data["pagination"].key?("page")
    assert response_data["pagination"].key?("per_page")
    assert response_data["pagination"].key?("total_count")
    assert response_data["pagination"].key?("total_pages")
  end

  test "should get index with read-only API key" do
    get api_v1_transactions_url, headers: api_headers(@read_only_api_key)
    assert_response :success
  end

  test "should filter transactions by account_id" do
    get api_v1_transactions_url, params: { account_id: @account.id }, headers: api_headers(@api_key)
    assert_response :success

    response_data = JSON.parse(response.body)
    response_data["transactions"].each do |transaction|
      assert_equal @account.id, transaction["account"]["id"]
    end
  end

  test "should filter transactions by date range" do
    start_date = 1.month.ago.to_date
    end_date = Date.current

    get api_v1_transactions_url,
        params: { start_date: start_date, end_date: end_date },
        headers: api_headers(@api_key)
    assert_response :success

    response_data = JSON.parse(response.body)
    response_data["transactions"].each do |transaction|
      transaction_date = Date.parse(transaction["date"])
      assert transaction_date >= start_date
      assert transaction_date <= end_date
    end
  end

  test "should search transactions" do
    # Create a transaction with a specific name for testing
    entry = @account.entries.create!(
      name: "Test Coffee Purchase",
      amount: 5.50,
      currency: "USD",
      date: Date.current,
      entryable: Transaction.new
    )

    get api_v1_transactions_url,
        params: { search: "Coffee" },
        headers: api_headers(@api_key)
    assert_response :success

    response_data = JSON.parse(response.body)
    found_transaction = response_data["transactions"].find { |t| t["id"] == entry.transaction.id }
    assert_not_nil found_transaction, "Should find the coffee transaction"
  end

  test "should paginate transactions" do
    get api_v1_transactions_url,
        params: { page: 1, per_page: 5 },
        headers: api_headers(@api_key)
    assert_response :success

    response_data = JSON.parse(response.body)
    assert response_data["transactions"].size <= 5
    assert_equal 1, response_data["pagination"]["page"]
    assert_equal 5, response_data["pagination"]["per_page"]
  end

  test "should reject index request without API key" do
    get api_v1_transactions_url
    assert_response :unauthorized
  end

  test "should reject index request with invalid API key" do
    get api_v1_transactions_url, headers: { "X-Api-Key" => "invalid-key" }
    assert_response :unauthorized
  end

  # SHOW action tests
  test "should show transaction with valid API key" do
    get api_v1_transaction_url(@transaction), headers: api_headers(@api_key)
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_equal @transaction.id, response_data["id"]
    assert response_data.key?("name")
    assert response_data.key?("amount")
    assert response_data.key?("date")
    assert response_data.key?("account")
  end

  test "should show transaction with read-only API key" do
    get api_v1_transaction_url(@transaction), headers: api_headers(@read_only_api_key)
    assert_response :success
  end

  test "should return 404 for non-existent transaction" do
    get api_v1_transaction_url(999999), headers: api_headers(@api_key)
    assert_response :not_found
  end

  test "should reject show request without API key" do
    get api_v1_transaction_url(@transaction)
    assert_response :unauthorized
  end

  # CREATE action tests
  test "should create transaction with valid parameters" do
    transaction_params = {
      transaction: {
        account_id: @account.id,
        name: "Test Transaction",
        amount: 25.00,
        date: Date.current,
        currency: "USD",
        nature: "expense"
      }
    }

    assert_difference("@account.entries.count", 1) do
      post api_v1_transactions_url,
           params: transaction_params,
           headers: api_headers(@api_key)
    end

    assert_response :created
    response_data = JSON.parse(response.body)
    assert_equal "Test Transaction", response_data["name"]
    assert_equal @account.id, response_data["account"]["id"]
  end

  test "should reject create with read-only API key" do
    transaction_params = {
      transaction: {
        account_id: @account.id,
        name: "Test Transaction",
        amount: 25.00,
        date: Date.current
      }
    }

    post api_v1_transactions_url,
         params: transaction_params,
         headers: api_headers(@read_only_api_key)
    assert_response :forbidden
  end

  test "should reject create with invalid parameters" do
    transaction_params = {
      transaction: {
        # Missing required fields
        name: "Test Transaction"
      }
    }

    post api_v1_transactions_url,
         params: transaction_params,
         headers: api_headers(@api_key)
    assert_response :unprocessable_entity
  end

  test "should reject create without API key" do
    post api_v1_transactions_url, params: { transaction: { name: "Test" } }
    assert_response :unauthorized
  end

  # UPDATE action tests
  test "should update transaction with valid parameters" do
    update_params = {
      transaction: {
        name: "Updated Transaction Name",
        amount: 30.00
      }
    }

    put api_v1_transaction_url(@transaction),
        params: update_params,
        headers: api_headers(@api_key)
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_equal "Updated Transaction Name", response_data["name"]
  end

  test "should reject update with read-only API key" do
    update_params = {
      transaction: {
        name: "Updated Transaction Name"
      }
    }

    put api_v1_transaction_url(@transaction),
        params: update_params,
        headers: api_headers(@read_only_api_key)
    assert_response :forbidden
  end

  test "should reject update for non-existent transaction" do
    put api_v1_transaction_url(999999),
        params: { transaction: { name: "Test" } },
        headers: api_headers(@api_key)
    assert_response :not_found
  end

  test "should reject update without API key" do
    put api_v1_transaction_url(@transaction), params: { transaction: { name: "Test" } }
    assert_response :unauthorized
  end

  # DESTROY action tests
  test "should destroy transaction" do
  entry_to_delete = @account.entries.create!(
    name: "Transaction to Delete",
    amount: 10.00,
    currency: "USD",
    date: Date.current,
    entryable: Transaction.new
  )
  transaction_to_delete = entry_to_delete.transaction

  assert_difference("@account.entries.count", -1) do
    delete api_v1_transaction_url(transaction_to_delete), headers: api_headers(@api_key)
  end

  assert_response :success
  response_data = JSON.parse(response.body)
  assert response_data.key?("message")
end

  test "should reject destroy with read-only API key" do
    delete api_v1_transaction_url(@transaction), headers: api_headers(@read_only_api_key)
    assert_response :forbidden
  end

  test "should reject destroy for non-existent transaction" do
    delete api_v1_transaction_url(999999), headers: api_headers(@api_key)
    assert_response :not_found
  end

  test "should reject destroy without API key" do
    delete api_v1_transaction_url(@transaction)
    assert_response :unauthorized
  end

  # JSON structure tests
  test "transaction JSON should have expected structure" do
    get api_v1_transaction_url(@transaction), headers: api_headers(@api_key)
    assert_response :success

    transaction_data = JSON.parse(response.body)

    # Basic fields
    assert transaction_data.key?("id")
    assert transaction_data.key?("date")
    assert transaction_data.key?("amount")
    assert transaction_data.key?("currency")
    assert transaction_data.key?("name")
    assert transaction_data.key?("classification")
    assert transaction_data.key?("created_at")
    assert transaction_data.key?("updated_at")

    # Account information
    assert transaction_data.key?("account")
    assert transaction_data["account"].key?("id")
    assert transaction_data["account"].key?("name")
    assert transaction_data["account"].key?("account_type")

    # Optional fields should be present (even if nil)
    assert transaction_data.key?("category")
    assert transaction_data.key?("merchant")
    assert transaction_data.key?("tags")
    assert transaction_data.key?("transfer")
    assert transaction_data.key?("notes")
  end

  test "transactions with transfers should include transfer information" do
    # Create a transfer between two accounts to test transfer rendering
    from_account = @family.accounts.create!(
      name: "Transfer From Account",
      balance: 1000,
      currency: "USD",
      accountable: Depository.new
    )

    to_account = @family.accounts.create!(
      name: "Transfer To Account",
      balance: 0,
      currency: "USD",
      accountable: Depository.new
    )

    transfer = Transfer::Creator.new(
      family: @family,
      source_account_id: from_account.id,
      destination_account_id: to_account.id,
      date: Date.current,
      amount: 100
    ).create

    get api_v1_transaction_url(transfer.inflow_transaction), headers: api_headers(@api_key)
    assert_response :success

    transaction_data = JSON.parse(response.body)
    assert_not_nil transaction_data["transfer"]
    assert transaction_data["transfer"].key?("id")
    assert transaction_data["transfer"].key?("amount")
    assert transaction_data["transfer"].key?("currency")
    assert transaction_data["transfer"].key?("other_account")
  end

  private

    def api_headers(api_key)
      { "X-Api-Key" => api_key.display_key }
    end
end
