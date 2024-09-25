class Import::Row < ApplicationRecord
  belongs_to :import

  def import!
    raise NotImplementedError, "Import row must implement import!"
  end
end
