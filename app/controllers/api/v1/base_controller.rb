# frozen_string_literal: true

class Api::V1::BaseController < ApplicationController
  include Doorkeeper::Rails::Helpers

  # Skip regular session-based authentication for API
  skip_authentication

  # Force JSON format for all API requests
  before_action :force_json_format
  # Use our custom authentication that supports both OAuth and API keys
  before_action :authenticate_request!
  before_action :check_api_key_rate_limit
  before_action :log_api_access

  # Override Doorkeeper's default behavior to return JSON instead of redirecting
  def doorkeeper_unauthorized_render_options(error: nil)
    { json: { error: "unauthorized", message: "Access token is invalid, expired, or missing" } }
  end

  # Error handling for common API errors
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from Doorkeeper::Errors::DoorkeeperError, with: :handle_unauthorized
  rescue_from ActionController::ParameterMissing, with: :handle_bad_request

  private

    # Force JSON format for all API requests
    def force_json_format
      request.format = :json
    end

    # Authenticate using either OAuth or API key
    def authenticate_request!
      authenticate_oauth || authenticate_api_key || render_unauthorized
    end

    # Try OAuth authentication first
    def authenticate_oauth
      return false unless request.headers["Authorization"].present?

      doorkeeper_authorize!
      @current_user = User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
      @authentication_method = :oauth
      true
    rescue Doorkeeper::Errors::DoorkeeperError
      false
    end

    # Try API key authentication
    def authenticate_api_key
      api_key_value = request.headers["X-Api-Key"]
      return false unless api_key_value

      @api_key = ApiKey.find_by_value(api_key_value)
      return false unless @api_key && @api_key.active?

      @current_user = @api_key.user
      @api_key.update_last_used!
      @authentication_method = :api_key
      @rate_limiter = ApiRateLimiter.new(@api_key)
      true
    end

    # Check rate limits for API key authentication
    def check_api_key_rate_limit
      return unless @authentication_method == :api_key && @rate_limiter

      if @rate_limiter.rate_limit_exceeded?
        usage_info = @rate_limiter.usage_info
        render_rate_limit_exceeded(usage_info)
        return false
      end

      # Increment request count for successful API key requests
      @rate_limiter.increment_request_count!

      # Add rate limit headers to response
      add_rate_limit_headers(@rate_limiter.usage_info)
    end

    # Render rate limit exceeded response
    def render_rate_limit_exceeded(usage_info)
      response.headers["X-RateLimit-Limit"] = usage_info[:rate_limit].to_s
      response.headers["X-RateLimit-Remaining"] = "0"
      response.headers["X-RateLimit-Reset"] = usage_info[:reset_time].to_s
      response.headers["Retry-After"] = usage_info[:reset_time].to_s

      Rails.logger.warn "API Rate Limit Exceeded: API Key #{@api_key.name} (User: #{@current_user.email}) - #{usage_info[:current_count]}/#{usage_info[:rate_limit]} requests"

      render_json({
        error: "rate_limit_exceeded",
        message: "Rate limit exceeded. Try again in #{usage_info[:reset_time]} seconds.",
        details: {
          limit: usage_info[:rate_limit],
          current: usage_info[:current_count],
          reset_in_seconds: usage_info[:reset_time]
        }
      }, status: :too_many_requests)
    end

    # Add rate limit headers to successful responses
    def add_rate_limit_headers(usage_info)
      response.headers["X-RateLimit-Limit"] = usage_info[:rate_limit].to_s
      response.headers["X-RateLimit-Remaining"] = usage_info[:remaining].to_s
      response.headers["X-RateLimit-Reset"] = usage_info[:reset_time].to_s
    end

    # Render unauthorized response
    def render_unauthorized
      render_json({ error: "unauthorized", message: "Access token or API key is invalid, expired, or missing" }, status: :unauthorized)
    end

    # Returns the user that owns the access token or API key
    def current_resource_owner
      @current_user
    end

    # Get current scopes from either authentication method
    def current_scopes
      case @authentication_method
      when :oauth
        doorkeeper_token&.scopes&.to_a || []
      when :api_key
        @api_key&.scopes || []
      else
        []
      end
    end

    # Check if the current authentication has the required scope
    def authorize_scope!(required_scope)
      scopes = current_scopes

      case required_scope.to_s
      when "read"
        # Read access requires either "read" or "read_write" scope
        has_access = scopes.include?("read") || scopes.include?("read_write")
      when "write"
        # Write access requires "read_write" scope
        has_access = scopes.include?("read_write")
      else
        # For any other scope, check exact match (backward compatibility)
        has_access = scopes.include?(required_scope.to_s)
      end

      unless has_access
        Rails.logger.warn "API Insufficient Scope: User #{current_resource_owner&.email} attempted to access #{required_scope} but only has #{scopes}"
        render_json({ error: "insufficient_scope", message: "This action requires the '#{required_scope}' scope" }, status: :forbidden)
        return false
      end
      true
    end

    # Consistent JSON response method
    def render_json(data, status: :ok)
      render json: data, status: status
    end

    # Error handlers
    def handle_not_found(exception)
      Rails.logger.warn "API Record Not Found: #{exception.message}"
      render_json({ error: "record_not_found", message: "The requested resource was not found" }, status: :not_found)
    end

    def handle_unauthorized(exception)
      Rails.logger.warn "API Unauthorized: #{exception.message}"
      render_json({ error: "unauthorized", message: "Access token is invalid or expired" }, status: :unauthorized)
    end

    def handle_bad_request(exception)
      Rails.logger.warn "API Bad Request: #{exception.message}"
      render_json({ error: "bad_request", message: "Required parameters are missing or invalid" }, status: :bad_request)
    end

    # Log API access for monitoring and debugging
    def log_api_access
      return unless current_resource_owner

      auth_info = case @authentication_method
      when :oauth
        "OAuth Token"
      when :api_key
        "API Key: #{@api_key.name}"
      else
        "Unknown"
      end

      Rails.logger.info "API Request: #{request.method} #{request.path} - User: #{current_resource_owner.email} (Family: #{current_resource_owner.family_id}) - Auth: #{auth_info}"
    end

    # Family-based access control helper (to be used by subcontrollers)
    def ensure_current_family_access(resource)
      return unless resource.respond_to?(:family_id)

      unless resource.family_id == current_resource_owner.family_id
        Rails.logger.warn "API Forbidden: User #{current_resource_owner.email} attempted to access resource from family #{resource.family_id}"
        render_json({ error: "forbidden", message: "Access denied to this resource" }, status: :forbidden)
        return false
      end

      true
    end
end
