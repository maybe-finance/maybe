class Account < ApplicationRecord
  belongs_to :family

  delegated_type :accountable, types: %w[ Account::Credit Account::Depository Account::Investment Account::Loan Account::OtherAsset Account::OtherLiability Account::Property Account::Vehicle], dependent: :destroy

  delegate :icon, :type_name, :color, to: :accountable

  # Class method to get a representative instance of each accountable type
  def self.accountable_type_instances
    accountable_types.map do |type|
      type.constantize.new
    end
  end
end
