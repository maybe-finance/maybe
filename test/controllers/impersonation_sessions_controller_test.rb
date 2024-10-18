require "test_helper"

class ImpersonationSessionsControllerTest < ActionDispatch::IntegrationTest
  test "impersonation session logs all activity for auditing" do
    sign_in impersonator = users(:maybe_support_staff)
    impersonated = users(:family_member)

    impersonator_session = impersonation_sessions(:in_progress)

    post join_impersonation_sessions_path, params: { impersonation_session_id: impersonator_session.id }

    assert_difference "impersonator_session.logs.count", 2 do
      get root_path
      get account_path(impersonated.family.accounts.first)
    end
  end

  test "super admin can request an impersonation session" do
    sign_in users(:maybe_support_staff)

    post impersonation_sessions_path, params: { impersonation_session: { impersonated_id: users(:family_member).id } }

    assert_equal "Request sent to user. Waiting for approval.", flash[:notice]
    assert_redirected_to root_path
  end

  test "super admin can join and leave an in progress impersonation session" do
    sign_in super_admin = users(:maybe_support_staff)

    impersonator_session = impersonation_sessions(:in_progress)

    super_admin_session = super_admin.sessions.order(created_at: :desc).first

    assert_nil super_admin_session.active_impersonator_session

    # Joining the session
    post join_impersonation_sessions_path, params: { impersonation_session_id: impersonator_session.id }
    assert_equal impersonator_session, super_admin_session.reload.active_impersonator_session
    assert_equal "Joined session", flash[:notice]
    assert_redirected_to root_path

    follow_redirect!

    # Leaving the session
    delete leave_impersonation_sessions_path
    assert_nil super_admin_session.reload.active_impersonator_session
    assert_equal "Left session", flash[:notice]
    assert_redirected_to root_path

    # Impersonation session still in progress because nobody has ended it yet
    assert_equal "in_progress", impersonator_session.reload.status
  end

  test "super admin can complete an impersonation session" do
    sign_in super_admin = users(:maybe_support_staff)

    impersonator_session = impersonation_sessions(:in_progress)

    put complete_impersonation_session_path(impersonator_session)

    assert_equal "Session completed", flash[:notice]
    assert_nil super_admin.sessions.order(created_at: :desc).first.active_impersonator_session
    assert_equal "complete", impersonator_session.reload.status
    assert_redirected_to root_path
  end

  test "regular user can complete an impersonation session" do
    sign_in regular_user = users(:family_member)

    impersonator_session = impersonation_sessions(:in_progress)

    put complete_impersonation_session_path(impersonator_session)

    assert_equal "Session completed", flash[:notice]
    assert_equal "complete", impersonator_session.reload.status
    assert_redirected_to root_path
  end

  test "super admin cannot accept an impersonation session" do
    sign_in super_admin = users(:maybe_support_staff)

    impersonator_session = impersonation_sessions(:in_progress)

    put approve_impersonation_session_path(impersonator_session)

    assert_response :not_found
  end

  test "regular user can accept an impersonation session" do
    sign_in regular_user = users(:family_member)

    impersonator_session = impersonation_sessions(:in_progress)

    put approve_impersonation_session_path(impersonator_session)

    assert_equal "Request approved", flash[:notice]
    assert_equal "in_progress", impersonator_session.reload.status
    assert_redirected_to root_path
  end

  test "regular user can reject an impersonation session" do
    sign_in regular_user = users(:family_member)

    impersonator_session = impersonation_sessions(:in_progress)

    put reject_impersonation_session_path(impersonator_session)

    assert_equal "Request rejected", flash[:notice]
    assert_equal "rejected", impersonator_session.reload.status
    assert_redirected_to root_path
  end
end
