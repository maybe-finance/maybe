class DestroyJob < ApplicationJob
  queue_as :low_priority

  def perform(model)
    model.destroy
  end
end
