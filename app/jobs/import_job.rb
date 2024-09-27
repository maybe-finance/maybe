class ImportJob < ApplicationJob
  queue_as :default

  def perform(import)
    import.publish
  end
end
