require "test_helper"

class Api::V1::AuthControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Clean up any existing invite codes
    InviteCode.destroy_all
    @device_info = {
      device_id: "test-device-123",
      device_name: "Test iPhone",
      device_type: "ios",
      os_version: "17.0",
      app_version: "1.0.0"
    }
  end

  test "should signup new user and return OAuth tokens" do
    assert_difference("User.count", 1) do
      assert_difference("MobileDevice.count", 1) do
        assert_difference("Doorkeeper::Application.count", 1) do
          assert_difference("Doorkeeper::AccessToken.count", 1) do
            post "/api/v1/auth/signup", params: {
              user: {
                email: "newuser@example.com",
                password: "SecurePass123!",
                first_name: "New",
                last_name: "User"
              },
              device: @device_info
            }
          end
        end
      end
    end

    assert_response :created
    response_data = JSON.parse(response.body)

    assert response_data["user"]["id"].present?
    assert_equal "newuser@example.com", response_data["user"]["email"]
    assert_equal "New", response_data["user"]["first_name"]
    assert_equal "User", response_data["user"]["last_name"]

    # OAuth token assertions
    assert response_data["access_token"].present?
    assert response_data["refresh_token"].present?
    assert_equal "Bearer", response_data["token_type"]
    assert_equal 2592000, response_data["expires_in"] # 30 days
    assert response_data["created_at"].present?

    # Verify the device was created
    new_user = User.find(response_data["user"]["id"])
    device = new_user.mobile_devices.first
    assert_equal @device_info[:device_id], device.device_id
    assert_equal @device_info[:device_name], device.device_name
    assert_equal @device_info[:device_type], device.device_type
  end

  test "should not signup without device info" do
    assert_no_difference("User.count") do
      post "/api/v1/auth/signup", params: {
        user: {
          email: "newuser@example.com",
          password: "SecurePass123!",
          first_name: "New",
          last_name: "User"
        }
      }
    end

    assert_response :bad_request
    response_data = JSON.parse(response.body)
    assert_equal "Device information is required", response_data["error"]
  end

  test "should not signup with invalid password" do
    assert_no_difference("User.count") do
      post "/api/v1/auth/signup", params: {
        user: {
          email: "newuser@example.com",
          password: "weak",
          first_name: "New",
          last_name: "User"
        },
        device: @device_info
      }
    end

    assert_response :unprocessable_entity
    response_data = JSON.parse(response.body)
    assert response_data["errors"].include?("Password must be at least 8 characters")
  end

  test "should not signup with duplicate email" do
    existing_user = users(:family_admin)

    assert_no_difference("User.count") do
      post "/api/v1/auth/signup", params: {
        user: {
          email: existing_user.email,
          password: "SecurePass123!",
          first_name: "Duplicate",
          last_name: "User"
        },
        device: @device_info
      }
    end

    assert_response :unprocessable_entity
  end

  test "should create user with admin role and family" do
    post "/api/v1/auth/signup", params: {
      user: {
        email: "newuser@example.com",
        password: "SecurePass123!",
        first_name: "New",
        last_name: "User"
      },
      device: @device_info
    }

    assert_response :created
    response_data = JSON.parse(response.body)

    new_user = User.find(response_data["user"]["id"])
    assert_equal "admin", new_user.role
    assert new_user.family.present?
  end

  test "should require invite code when enabled" do
    # Mock invite code requirement
    Api::V1::AuthController.any_instance.stubs(:invite_code_required?).returns(true)

    assert_no_difference("User.count") do
      post "/api/v1/auth/signup", params: {
        user: {
          email: "newuser@example.com",
          password: "SecurePass123!",
          first_name: "New",
          last_name: "User"
        },
        device: @device_info
      }
    end

    assert_response :forbidden
    response_data = JSON.parse(response.body)
    assert_equal "Invite code is required", response_data["error"]
  end

  test "should signup with valid invite code when required" do
    # Create a valid invite code
    invite_code = InviteCode.create!

    # Mock invite code requirement
    Api::V1::AuthController.any_instance.stubs(:invite_code_required?).returns(true)

    assert_difference("User.count", 1) do
      assert_difference("InviteCode.count", -1) do
        post "/api/v1/auth/signup", params: {
          user: {
            email: "newuser@example.com",
            password: "SecurePass123!",
            first_name: "New",
            last_name: "User"
          },
          device: @device_info,
          invite_code: invite_code.token
        }
      end
    end

    assert_response :created
  end

  test "should reject invalid invite code" do
    # Mock invite code requirement
    Api::V1::AuthController.any_instance.stubs(:invite_code_required?).returns(false)

    assert_no_difference("User.count") do
      post "/api/v1/auth/signup", params: {
        user: {
          email: "newuser@example.com",
          password: "SecurePass123!",
          first_name: "New",
          last_name: "User"
        },
        device: @device_info,
        invite_code: "invalid_code"
      }
    end

    assert_response :forbidden
    response_data = JSON.parse(response.body)
    assert_equal "Invalid invite code", response_data["error"]
  end

  test "should login existing user and return OAuth tokens" do
    user = users(:family_admin)
    password = user_password_test

    # Ensure user has no mobile devices
    user.mobile_devices.destroy_all

    assert_difference("MobileDevice.count", 1) do
      assert_difference("Doorkeeper::AccessToken.count", 1) do
        post "/api/v1/auth/login", params: {
          email: user.email,
          password: password,
          device: @device_info
        }
      end
    end

    assert_response :success
    response_data = JSON.parse(response.body)

    assert_equal user.id.to_s, response_data["user"]["id"]
    assert_equal user.email, response_data["user"]["email"]

    # OAuth token assertions
    assert response_data["access_token"].present?
    assert response_data["refresh_token"].present?
    assert_equal "Bearer", response_data["token_type"]
    assert_equal 2592000, response_data["expires_in"] # 30 days

    # Verify the device
    device = user.mobile_devices.where(device_id: @device_info[:device_id]).first
    assert device.present?
    assert device.active?
  end

  test "should require MFA when enabled" do
    user = users(:family_admin)
    password = user_password_test

    # Enable MFA for user
    user.setup_mfa!
    user.enable_mfa!

    post "/api/v1/auth/login", params: {
      email: user.email,
      password: password,
      device: @device_info
    }

    assert_response :unauthorized
    response_data = JSON.parse(response.body)
    assert_equal "Two-factor authentication required", response_data["error"]
    assert response_data["mfa_required"]
  end

  test "should login with valid MFA code" do
    user = users(:family_admin)
    password = user_password_test

    # Enable MFA for user
    user.setup_mfa!
    user.enable_mfa!
    totp = ROTP::TOTP.new(user.otp_secret)

    assert_difference("Doorkeeper::AccessToken.count", 1) do
      post "/api/v1/auth/login", params: {
        email: user.email,
        password: password,
        otp_code: totp.now,
        device: @device_info
      }
    end

    assert_response :success
    response_data = JSON.parse(response.body)
    assert response_data["access_token"].present?
  end

  test "should revoke existing tokens for same device on login" do
    user = users(:family_admin)
    password = user_password_test

    # Create an existing device and token
    device = user.mobile_devices.create!(@device_info)
    oauth_app = device.create_oauth_application!
    existing_token = Doorkeeper::AccessToken.create!(
      application: oauth_app,
      resource_owner_id: user.id,
      expires_in: 30.days.to_i,
      scopes: "read_write"
    )

    assert existing_token.accessible?

    post "/api/v1/auth/login", params: {
      email: user.email,
      password: password,
      device: @device_info
    }

    assert_response :success

    # Check that old token was revoked
    existing_token.reload
    assert existing_token.revoked?
  end

  test "should not login with invalid password" do
    user = users(:family_admin)

    assert_no_difference("Doorkeeper::AccessToken.count") do
      post "/api/v1/auth/login", params: {
        email: user.email,
        password: "wrong_password",
        device: @device_info
      }
    end

    assert_response :unauthorized
    response_data = JSON.parse(response.body)
    assert_equal "Invalid email or password", response_data["error"]
  end

  test "should not login with non-existent email" do
    assert_no_difference("Doorkeeper::AccessToken.count") do
      post "/api/v1/auth/login", params: {
        email: "nonexistent@example.com",
        password: user_password_test,
        device: @device_info
      }
    end

    assert_response :unauthorized
    response_data = JSON.parse(response.body)
    assert_equal "Invalid email or password", response_data["error"]
  end

  test "should not login without device info" do
    user = users(:family_admin)

    assert_no_difference("Doorkeeper::AccessToken.count") do
      post "/api/v1/auth/login", params: {
        email: user.email,
        password: user_password_test
      }
    end

    assert_response :bad_request
    response_data = JSON.parse(response.body)
    assert_equal "Device information is required", response_data["error"]
  end

  test "should refresh access token with valid refresh token" do
    user = users(:family_admin)
    device = user.mobile_devices.create!(@device_info)
    oauth_app = device.create_oauth_application!

    # Create initial token
    initial_token = Doorkeeper::AccessToken.create!(
      application: oauth_app,
      resource_owner_id: user.id,
      expires_in: 30.days.to_i,
      scopes: "read_write",
      use_refresh_token: true
    )

    # Wait to ensure different timestamps
    sleep 0.1

    assert_difference("Doorkeeper::AccessToken.count", 1) do
      post "/api/v1/auth/refresh", params: {
        refresh_token: initial_token.refresh_token,
        device: @device_info
      }
    end

    assert_response :success
    response_data = JSON.parse(response.body)

    # New token assertions
    assert response_data["access_token"].present?
    assert response_data["refresh_token"].present?
    assert_not_equal initial_token.token, response_data["access_token"]
    assert_equal 2592000, response_data["expires_in"]

    # Old token should be revoked
    initial_token.reload
    assert initial_token.revoked?
  end

  test "should not refresh with invalid refresh token" do
    assert_no_difference("Doorkeeper::AccessToken.count") do
      post "/api/v1/auth/refresh", params: {
        refresh_token: "invalid_token",
        device: @device_info
      }
    end

    assert_response :unauthorized
    response_data = JSON.parse(response.body)
    assert_equal "Invalid refresh token", response_data["error"]
  end

  test "should not refresh without refresh token" do
    post "/api/v1/auth/refresh", params: {
      device: @device_info
    }

    assert_response :bad_request
    response_data = JSON.parse(response.body)
    assert_equal "Refresh token is required", response_data["error"]
  end
end
