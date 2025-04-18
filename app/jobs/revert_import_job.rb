class RevertImportJob < ApplicationJob
  queue_as :medium_priority

  def perform(import)
    import.revert
  end
end
