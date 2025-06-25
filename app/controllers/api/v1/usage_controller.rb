class Api::V1::UsageController < Api::V1::BaseController
  # GET /api/v1/usage
  def show
    return unless authorize_scope!(:read)

    case @authentication_method
    when :api_key
      usage_info = @rate_limiter.usage_info
      render_json({
        api_key: {
          name: @api_key.name,
          scopes: @api_key.scopes,
          last_used_at: @api_key.last_used_at,
          created_at: @api_key.created_at
        },
        rate_limit: {
          tier: usage_info[:tier],
          limit: usage_info[:rate_limit],
          current_count: usage_info[:current_count],
          remaining: usage_info[:remaining],
          reset_in_seconds: usage_info[:reset_time],
          reset_at: Time.current + usage_info[:reset_time].seconds
        }
      })
    when :oauth
      # For OAuth, we don't track detailed usage yet, but we can return basic info
      render_json({
        authentication_method: "oauth",
        message: "Detailed usage tracking is available for API key authentication"
      })
    else
      render_json({
        error: "invalid_authentication_method",
        message: "Unable to determine usage information"
      }, status: :bad_request)
    end
  end
end
