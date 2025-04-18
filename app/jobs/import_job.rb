class ImportJob < ApplicationJob
  queue_as :high_priority

  def perform(import)
    import.publish
  end
end
