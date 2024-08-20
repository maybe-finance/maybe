require "test_helper"

class PdfRegexesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @pdf_regex = pdf_regexes(:awesome_bank_pdf_regex)

    @pdf_regex_params = {
      name: "name",
      transaction_line_regex_str: "transaction_line_regex_str",
      metadata_regex_str: "metadata_regex_str",
      pdf_transaction_date_format: "pdf_transaction_date_format",
      pdf_range_date_format: "pdf_range_date_format"
    }
  end

  test "index" do
    get pdf_regexes_path
    assert_response :success
  end

  test "new" do
    get new_pdf_regex_path
    assert_response :success
  end

  test "should create pdf_regex" do
    assert_difference("PdfRegex.count") do
      post pdf_regexes_url, params: { pdf_regex: @pdf_regex_params }
    end

    assert_redirected_to pdf_regexes_path
  end

  test "should update pdf_regex" do
    patch pdf_regex_url(@pdf_regex), params: { pdf_regex: @pdf_regex_params }
    assert_redirected_to pdf_regexes_path
  end

  test "should destroy pdf_regex" do
    assert_difference("PdfRegex.count", -1) do
      delete pdf_regex_url(@pdf_regex)
    end

    assert_redirected_to pdf_regexes_path
  end
end
