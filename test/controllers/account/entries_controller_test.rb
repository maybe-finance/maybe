require "test_helper"

class Account::EntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @transaction = account_entries :transaction
    @valuation = account_entries :valuation
    @trade = account_entries :trade
  end

  # =================
  # Shared
  # =================

  test "should destroy entry" do
    [ @transaction, @valuation, @trade ].each do |entry|
      assert_difference -> { Account::Entry.count } => -1, -> { entry.entryable_class.count } => -1 do
        delete account_entry_url(entry.account, entry)
      end

      assert_redirected_to account_url(entry.account)
      assert_enqueued_with(job: AccountSyncJob)
    end
  end

  test "shows entry" do
    [ @transaction, @valuation, @trade ].each do |entry|
      get account_entry_url(entry.account, entry)
      assert_response :success
    end
  end

  test "can update entry without entryable attributes" do
    [ @transaction, @valuation, @trade ].each do |entry|
      assert_no_difference_in_entries do
        patch account_entry_url(entry.account, entry), params: {
          account_entry: generic_entry_attributes
        }
      end

      assert_redirected_to account_entry_url(entry.account, entry)
      assert_enqueued_with(job: AccountSyncJob)
    end
  end

  # =================
  # Valuations
  # =================

  test "edit valuation entry" do
    get edit_account_entry_url(@valuation.account, @valuation)
    assert_response :success
  end

  test "error when valuation already exists for date" do
    assert_no_difference_in_entries do
      post account_entries_url(@valuation.account), params: {
        account_entry: {
          amount: 19800,
          date: @valuation.date,
          currency: @valuation.currency,
          entryable_type: "Account::Valuation",
          entryable_attributes: {}
        }
      }
    end

    assert_equal "Date has already been taken", flash[:alert]
    assert_redirected_to account_path(@valuation.account)
  end

  # =================
  # Trades
  # =================

  test "creates trade buy entry" do
    assert_difference [ "Account::Entry.count", "Account::Trade.count", "Security.count" ], 1 do
      post account_entries_url(@trade.account), params: {
        account_entry: {
          type:                 "buy",
          name:                 "Name",
          date:                 Date.current,
          currency:             "USD",
          entryable_type:       @trade.entryable_type,
          entryable_attributes: {
            qty:      10,
            price:    10,
            currency: "USD",
            ticker:   "NVDA"
          }
        }
      }
    end

    created_entry = Account::Entry.order(created_at: :desc).first

    assert created_entry.amount.positive?
    assert created_entry.account_trade.qty.positive?
    assert_equal "Trade created", flash[:notice]
    assert_enqueued_with job: AccountSyncJob
    assert_redirected_to account_path(@trade.account)
  end

  test "creates trade sell entry" do
    assert_difference [ "Account::Entry.count", "Account::Trade.count" ], 1 do
      post account_entries_url(@trade.account), params: {
        account_entry: {
          type:                 "sell",
          name:                 "Name",
          date: Date.current,
          currency: "USD",
          entryable_type:       @trade.entryable_type,
          entryable_attributes: {
            qty:      10,
            price:    10,
            currency: "USD",
            ticker:   "AAPL"
          }
        }
      }
    end

    created_entry = Account::Entry.order(created_at: :desc).first

    assert created_entry.amount.negative?
    assert created_entry.account_trade.qty.negative?
    assert_equal "Trade created", flash[:notice]
    assert_enqueued_with job: AccountSyncJob
    assert_redirected_to account_path(@trade.account)
  end


  private

    # Simple guard to verify that nested attributes are passed the record ID to avoid new creation of record
    # See `update_only` option of accepts_nested_attributes_for
    def assert_no_difference_in_entries(&block)
      assert_no_difference [ "Account::Entry.count", "Account::Transaction.count", "Account::Valuation.count" ], &block
    end

    def generic_entry_attributes
      {
        name:     "Name",
        date:     Date.current,
        currency: "USD",
        amount:   100
      }
    end
end
