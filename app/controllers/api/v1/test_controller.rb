# frozen_string_literal: true

# Test controller for API V1 Base Controller functionality
# This controller is only used for testing the base controller behavior
class Api::V1::TestController < Api::V1::BaseController
  def index
    render_json({ message: "test_success", user: current_resource_owner&.email })
  end

  def not_found
    # Trigger RecordNotFound error for testing error handling
    raise ActiveRecord::RecordNotFound, "Test record not found"
  end

      def family_access
    # Test family-based access control
    # Create a mock resource that belongs to a different family
    mock_resource = OpenStruct.new(family_id: 999)  # Different family ID

    # Check family access - if it returns false, it already rendered the error
    if ensure_current_family_access(mock_resource)
      # If we get here, access was allowed
      render_json({ family_id: current_resource_owner.family_id })
    end
  end
end
