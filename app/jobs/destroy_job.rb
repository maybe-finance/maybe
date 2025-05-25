class DestroyJob < ApplicationJob
  queue_as :low_priority

  def perform(model)
    model.destroy
  rescue => e
    model.update!(scheduled_for_deletion: false) # Let's the user try again by resetting the state
  end
end
