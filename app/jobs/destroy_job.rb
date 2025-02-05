class DestroyJob < ApplicationJob
  queue_as :latency_low

  def perform(model)
    model.destroy
  end
end
