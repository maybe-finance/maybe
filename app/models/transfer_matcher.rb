class TransferMatcher
  attr_reader :family

  def initialize(family)
    @family = family
  end

  def match!(transaction_entries)
    ActiveRecord::Base.transaction do
      transaction_entries.each do |entry|
        entry.entryable.update!(category_id: transfer_category.id)
      end

      create_transfers(transaction_entries)
    end
  end

  private
    def create_transfers(entries)
      matches = entries.to_a.combination(2).select do |entry1, entry2|
        entry1.amount == -entry2.amount &&
        entry1.account_id != entry2.account_id &&
        (entry1.date - entry2.date).abs <= 4
      end

      matches.each do |match|
        Account::Transfer.create!(entries: match)
      end
    end

    def transfer_category
      @transfer_category ||= family.categories.find_or_create_by!(classification: "transfer") do |category|
        category.name = "Transfer"
      end
    end
end
