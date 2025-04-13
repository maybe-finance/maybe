require "test_helper"

class Account::TransactionsControllerTest < ActionDispatch::IntegrationTest
  include EntryableResourceInterfaceTest

  setup do
    sign_in @user = users(:family_admin)
    @entry = account_entries(:transaction)
  end

  test "creates with transaction details" do
    assert_difference [ "Account::Entry.count", "Account::Transaction.count" ], 1 do
      post account_transactions_url, params: {
        account_entry: {
          account_id: @entry.account_id,
          name: "New transaction",
          date: Date.current,
          currency: "USD",
          amount: 100,
          nature: "inflow",
          entryable_attributes: {
            tag_ids: [ Tag.first.id, Tag.second.id ],
            category_id: Category.first.id,
            merchant_id: Merchant.first.id
          }
        }
      }
    end

    created_entry = Account::Entry.order(:created_at).last
    created_transaction = created_entry.account_transaction

    assert created_entry.locked?(:name)
    assert created_entry.locked?(:date)
    assert created_entry.locked?(:amount)
    assert created_entry.locked?(:currency)

    assert created_transaction.locked?(:tag_ids)
    assert created_transaction.locked?(:category_id)
    assert created_transaction.locked?(:merchant_id)

    assert_redirected_to account_url(created_entry.account)
    assert_equal "Entry created", flash[:notice]
    assert_enqueued_with(job: SyncJob)
  end

  test "updates with transaction details" do
    assert_no_difference [ "Account::Entry.count", "Account::Transaction.count" ] do
      patch account_transaction_url(@entry), params: {
        account_entry: {
          name: "Updated name",
          date: Date.current,
          currency: "USD",
          amount: 100,
          nature: "inflow",
          entryable_type: @entry.entryable_type,
          notes: "test notes",
          excluded: false,
          entryable_attributes: {
            id: @entry.entryable_id,
            tag_ids: [ Tag.first.id, Tag.second.id ],
            category_id: categories(:subcategory).id,
            merchant_id: merchants(:netflix).id
          }
        }
      }
    end

    @entry.reload

    assert_equal "Updated name", @entry.name
    assert_equal Date.current, @entry.date
    assert_equal "USD", @entry.currency
    assert_equal -100, @entry.amount
    assert_equal [ Tag.first.id, Tag.second.id ], @entry.entryable.tag_ids.sort
    assert_equal categories(:subcategory).id, @entry.entryable.category_id
    assert_equal merchants(:netflix).id, @entry.entryable.merchant_id
    assert_equal "test notes", @entry.notes
    assert_equal false, @entry.excluded

    assert @entry.locked?(:name)
    assert @entry.locked?(:date)
    assert @entry.locked?(:amount)
    assert @entry.locked?(:notes)

    assert @entry.account_transaction.locked?(:tag_ids)
    assert @entry.account_transaction.locked?(:category_id)
    assert @entry.account_transaction.locked?(:merchant_id)

    assert_equal "Entry updated", flash[:notice]
    assert_redirected_to account_url(@entry.account)
    assert_enqueued_with(job: SyncJob)
  end

  test "can destroy many transactions at once" do
    transactions = @user.family.entries.account_transactions
    delete_count = transactions.size

    assert_difference([ "Account::Transaction.count", "Account::Entry.count" ], -delete_count) do
      post bulk_delete_account_transactions_url, params: {
        bulk_delete: {
          entry_ids: transactions.pluck(:id)
        }
      }
    end

    assert_redirected_to transactions_url
    assert_equal "#{delete_count} transactions deleted", flash[:notice]
  end

  test "can update many transactions at once" do
    transaction_entries = @user.family.entries.account_transactions

    new_category = @user.family.categories.create!(name: "New category")
    new_merchant = @user.family.merchants.create!(type: "FamilyMerchant", name: "New merchant")

    assert_difference [ "Account::Entry.count", "Account::Transaction.count" ], 0 do
      post bulk_update_account_transactions_url, params: {
        bulk_update: {
          entry_ids: transaction_entries.map(&:id),
          date: 5.days.ago.to_date,
          category_id: new_category.id,
          merchant_id: new_merchant.id,
          tag_ids: [ Tag.first.id, Tag.second.id ],
          notes: "Updated note"
        }
      }
    end

    assert_redirected_to transactions_url
    assert_equal "#{transaction_entries.count} transactions updated", flash[:notice]

    transaction_entries.reload.each do |transaction_entry|
      assert_equal 5.days.ago.to_date, transaction_entry.date
      assert_equal new_category, transaction_entry.account_transaction.category
      assert_equal new_merchant, transaction_entry.account_transaction.merchant
      assert_equal "Updated note", transaction_entry.notes
      assert_equal [ Tag.first.id, Tag.second.id ], transaction_entry.entryable.tag_ids.sort

      assert transaction_entry.locked?(:date)
      assert transaction_entry.locked?(:notes)

      assert transaction_entry.account_transaction.locked?(:category_id)
      assert transaction_entry.account_transaction.locked?(:merchant_id)
      assert transaction_entry.account_transaction.locked?(:tag_ids)
    end
  end
end
