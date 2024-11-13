class DestroyJob < ApplicationJob
  queue_as :default

  def perform(model)
    model.destroy
  end
end
