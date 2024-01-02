require "application_system_test_case"

class PortfoliosTest < ApplicationSystemTestCase
  setup do
    @portfolio = portfolios(:one)
  end

  test "visiting the index" do
    visit portfolios_url
    assert_selector "h1", text: "Portfolios"
  end

  test "should create portfolio" do
    visit portfolios_url
    click_on "New portfolio"

    fill_in "Name", with: @portfolio.name
    fill_in "User", with: @portfolio.user_id
    click_on "Create Portfolio"

    assert_text "Portfolio was successfully created"
    click_on "Back"
  end

  test "should update Portfolio" do
    visit portfolio_url(@portfolio)
    click_on "Edit this portfolio", match: :first

    fill_in "Name", with: @portfolio.name
    fill_in "User", with: @portfolio.user_id
    click_on "Update Portfolio"

    assert_text "Portfolio was successfully updated"
    click_on "Back"
  end

  test "should destroy Portfolio" do
    visit portfolio_url(@portfolio)
    click_on "Destroy this portfolio", match: :first

    assert_text "Portfolio was successfully destroyed"
  end
end
