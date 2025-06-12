# frozen_string_literal: true

class Api::V1::BaseController < ApplicationController
  include Doorkeeper::Rails::Helpers

  # Skip regular session-based authentication for API
  skip_authentication

  # Require OAuth authentication for all API actions
  before_action :doorkeeper_authorize!
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

  # Returns the user that owns the access token
  def current_resource_owner
    @current_resource_owner ||= User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
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
    return unless doorkeeper_token && current_resource_owner

    Rails.logger.info "API Request: #{request.method} #{request.path} - User: #{current_resource_owner.email} (Family: #{current_resource_owner.family_id})"
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