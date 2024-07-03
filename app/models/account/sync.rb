class Account::Sync < ApplicationRecord
  belongs_to :account

  scope :incomplete, -> { where.not(status: "complete") }

  class << self
    def start_or_resume(account, start_date)
    end

    private

      def find_or_create_sync(account, start_date)
        find_or_create_by!(account:, start_date:)
      end
  end
end
