require "test_helper"

class Import::ConfigurationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @import = imports(:transaction)
  end

  test "show" do
    get import_configuration_url(@import)
    assert_response :success
  end

  test "updating a valid configuration regenerates rows" do
    TransactionImport.any_instance.expects(:generate_rows_from_csv).once

    patch import_configuration_url(@import), params: {
      import: {
        date_col_label: "Date",
        date_format: "%Y-%m-%d",
        name_col_label: "Name",
        category_col_label: "Category",
        tags_col_label: "Tags",
        amount_col_label: "Amount",
        amount_sign_format: "income_is_positive",
        account_col_label: "Account"
      }
    }

    assert_redirected_to import_clean_url(@import)
    assert_equal "Import configured successfully.", flash[:notice]
  end
end
