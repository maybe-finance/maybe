require "test_helper"

class InstitutionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:family_admin)
    @institution = institutions(:chase)
  end

  test "should get new" do
    get new_institution_url
    assert_response :success
  end

  test "can create institution" do
    assert_difference("Institution.count", 1) do
      post institutions_url, params: {
        institution: {
          name: "New institution"
        }
      }
    end

    assert_redirected_to accounts_url
    assert_equal "Institution created", flash[:notice]
  end

  test "should get edit" do
    get edit_institution_url(@institution)

    assert_response :success
  end

  test "should update institution" do
    patch institution_url(@institution), params: {
      institution: {
        name: "New Institution Name",
        logo: file_fixture_upload("square-placeholder.png", "image/png", :binary)
      }
    }

    assert_redirected_to accounts_url
    assert_equal "Institution updated", flash[:notice]
  end

  test "can destroy institution without destroying accounts" do
    assert @institution.accounts.count > 0

    assert_difference -> { Institution.count } => -1, -> { Account.count } => 0 do
      delete institution_url(@institution)
    end

    assert_redirected_to accounts_url
    assert_equal "Institution deleted", flash[:notice]
  end
end
