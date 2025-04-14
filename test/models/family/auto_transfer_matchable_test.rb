require "test_helper"

class Family::AutoTransferMatchableTest < ActiveSupport::TestCase
  include EntriesTestHelper

  setup do
    @family = families(:dylan_family)
    @depository = accounts(:depository)
    @credit_card = accounts(:credit_card)
  end

  test "auto-matches transfers" do
    outflow_entry = create_transaction(date: 1.day.ago.to_date, account: @depository, amount: 500)
    inflow_entry = create_transaction(date: Date.current, account: @credit_card, amount: -500)

    assert_difference -> { Transfer.count } => 1 do
      @family.auto_match_transfers!
    end
  end

  # In this scenario, our matching logic should find 4 potential matches.  These matches should be ranked based on
  # days apart, then de-duplicated so that we aren't auto-matching the same transaction across multiple transfers.
  test "when 2 options exist, only auto-match one at a time, ranked by days apart" do
    yesterday_outflow = create_transaction(date: 1.day.ago.to_date, account: @depository, amount: 500)
    yesterday_inflow = create_transaction(date: 1.day.ago.to_date, account: @credit_card, amount: -500)

    today_outflow = create_transaction(date: Date.current, account: @depository, amount: 500)
    today_inflow = create_transaction(date: Date.current, account: @credit_card, amount: -500)

    assert_difference -> { Transfer.count } => 2 do
      @family.auto_match_transfers!
    end
  end

  test "does not auto-match any transfers that have been rejected by user already" do
    outflow = create_transaction(date: Date.current, account: @depository, amount: 500)
    inflow = create_transaction(date: Date.current, account: @credit_card, amount: -500)

    RejectedTransfer.create!(inflow_transaction_id: inflow.entryable_id, outflow_transaction_id: outflow.entryable_id)

    assert_no_difference -> { Transfer.count } do
      @family.auto_match_transfers!
    end
  end

  test "does not consider inactive accounts when matching transfers" do
    @depository.update!(is_active: false)

    outflow = create_transaction(date: Date.current, account: @depository, amount: 500)
    inflow = create_transaction(date: Date.current, account: @credit_card, amount: -500)

    assert_no_difference -> { Transfer.count } do
      @family.auto_match_transfers!
    end
  end
end
