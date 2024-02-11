require 'application_system_test_case'

class AccountsList < ApplicationSystemTestCase
  setup do
    @user = users(:bob)
    @accountable = Accountable.from_type('Account::Credit')&.create!

    Account.create!(
      subtype: "credit",
      family_id: @user.family_id,
      name: 'Credit Card Account Name',
      accountable_type: 'Account::Credit',
      accountable_id: @accountable.id,
      original_balance: 1000,
    )

    sign_in @user
  end

  test 'shows sidebar' do
    assert_text 'Credit Card'
  end

  test 'persists sidebar collapsed state' do
    assert_no_text 'Credit Card Account Name'

    find("#Credit").click

    visit current_url

    assert_text 'Credit Card Account Name'
  end

end
