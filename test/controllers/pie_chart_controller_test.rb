require "application_system_test_case"

class PieChartControllerTest < ApplicationSystemTestCase

  setup do
    sign_in @user = users(:family_admin)
    @account = accounts(:credit_card)
  end

  test "pie chart values is displayed correctly when cents are defined" do
    assert_amount_balance '48550.80'
  end

  private
  def assert_amount_balance(expected_value)
    value_element = find('div.absolute.inset-0.w-full.text-center p span.text-xl') # Fetch the pie chart text
    entire_text = value_element.find(:xpath, '..').text # Get full text of the <p> element
    extracted_value = entire_text.strip.gsub(/[^\d.]/, '').sub(/^0+/, '') # Removing non-digit characters except the decimal point
    assert_equal expected_value, extracted_value, "The pie chart value is not displayed correctly"
  end

end