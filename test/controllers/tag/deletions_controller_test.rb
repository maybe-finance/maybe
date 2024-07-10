require "test_helper"

class Tag::DeletionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @tag = tags(:one)
  end

  test "should get new" do
    get new_tag_deletion_url(@tag)
    assert_response :success
  end

  test "create with replacement" do
    replacement_tag = tags(:two)

    affected_transaction_count = @tag.transactions.count

    assert affected_transaction_count > 0

    assert_difference -> { Tag.count } => -1, -> { replacement_tag.transactions.count } => affected_transaction_count do
      post tag_deletions_url(@tag), params: { replacement_tag_id: replacement_tag.id }
    end
  end

  test "create without replacement" do
    affected_transactions = @tag.transactions

    assert affected_transactions.count > 0

    assert_difference -> { Tag.count } => -1, -> { Tagging.count } => affected_transactions.count * -1 do
      post tag_deletions_url(@tag)
    end
  end
end
