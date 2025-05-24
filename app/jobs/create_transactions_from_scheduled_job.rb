class CreateTransactionsFromScheduledJob < ApplicationJob
  queue_as :default

  def perform(*args)
    today = Date.current
    due_transactions = ScheduledTransaction.where("next_occurrence_date <= ?", today)

    due_transactions.each do |scheduled_transaction|
      ActiveRecord::Base.transaction do
        create_transaction_from_scheduled(scheduled_transaction, today)
        update_scheduled_transaction(scheduled_transaction, today)
      rescue StandardError => e
        Rails.logger.error "Error processing scheduled transaction #{scheduled_transaction.id}: #{e.message}"
        # Optionally, re-raise the error if you want the job to retry
        # raise e
      end
    end
  end

  private

  def create_transaction_from_scheduled(scheduled_transaction, date)
    account = scheduled_transaction.account
    # Assuming scheduled transactions are expenses, store amount as negative
    amount = -scheduled_transaction.amount.abs

    entry_attributes = {
      account_id: account.id,
      name: scheduled_transaction.description,
      amount: amount,
      currency: scheduled_transaction.currency,
      date: date,
      entryable_attributes: {
        category_id: scheduled_transaction.category_id,
        merchant_id: scheduled_transaction.merchant_id
        # tag_ids could be added here if scheduled transactions support tags
      }
    }

    entry = account.entries.new(entry_attributes)
    entry.entryable_type = "Transaction" # Explicitly set entryable_type

    unless entry.save
      Rails.logger.error "Failed to create transaction for scheduled transaction #{scheduled_transaction.id}: #{entry.errors.full_messages.join(', ')}"
      raise ActiveRecord::Rollback # Rollback transaction if entry creation fails
    end
  end

  def update_scheduled_transaction(scheduled_transaction, current_date)
    if scheduled_transaction.installments.present? && scheduled_transaction.installments > 0
      scheduled_transaction.current_installment += 1
      if scheduled_transaction.current_installment >= scheduled_transaction.installments
        scheduled_transaction.destroy!
        return
      end
    end

    next_date = calculate_next_occurrence(scheduled_transaction.next_occurrence_date, scheduled_transaction.frequency, current_date)
    scheduled_transaction.next_occurrence_date = next_date

    if scheduled_transaction.end_date.present? && next_date > scheduled_transaction.end_date
      if scheduled_transaction.installments.blank? || (scheduled_transaction.installments.present? && scheduled_transaction.current_installment < scheduled_transaction.installments)
        # If it's a recurring transaction (not installment-based) or an installment-based one that hasn't completed all installments,
        # but the next occurrence is past the end_date, destroy it.
        scheduled_transaction.destroy!
        return
      end
    end

    # If next_occurrence_date was in the past, ensure it's set to a future date
    # This can happen if the job hasn't run for a while.
    while scheduled_transaction.next_occurrence_date <= current_date && !scheduled_transaction.destroyed?
      scheduled_transaction.next_occurrence_date = calculate_next_occurrence(scheduled_transaction.next_occurrence_date, scheduled_transaction.frequency, current_date)
      if scheduled_transaction.end_date.present? && scheduled_transaction.next_occurrence_date > scheduled_transaction.end_date
         scheduled_transaction.destroy!
         return
      end
    end

    scheduled_transaction.save! unless scheduled_transaction.destroyed?
  end

  def calculate_next_occurrence(current_next_date, frequency, processing_date)
    # If current_next_date is in the past, start calculations from processing_date
    # to ensure the next occurrence is in the future.
    base_date = [current_next_date, processing_date].max

    case frequency.downcase
    when 'daily'
      base_date + 1.day
    when 'weekly'
      base_date + 1.week
    when 'monthly'
      calculate_next_monthly_date(base_date)
    when 'yearly'
      base_date + 1.year
    # Add other frequencies as needed, e.g., 'bi-weekly', 'quarterly'
    # when 'bi-weekly'
    #   base_date + 2.weeks
    else
      # Default or unknown frequency, maybe set to a distant future date or raise error
      Rails.logger.warn "Unknown frequency: #{frequency} for scheduled transaction. Defaulting to 1 month."
      calculate_next_monthly_date(base_date)
    end
  end

  def calculate_next_monthly_date(base_date)
    # Attempt to advance by one month
    next_month_date = base_date + 1.month

    # If the day of the month changed due to varying month lengths (e.g., Jan 31 to Feb 28),
    # it means the original day doesn't exist in the next month.
    # In such cases, Rails' `+ 1.month` correctly lands on the last day of that shorter month.
    # If we want to stick to the original day of the month where possible,
    # and it's not the end of the month, we might need more complex logic.
    # However, for most common scenarios (e.g., payment on the 1st, 15th), `+ 1.month` is fine.
    # If the scheduled day was, say, the 31st, and next month is February, it will become Feb 28th/29th.
    # If the next month after that is March, `+ 1.month` from Feb 28th will be March 28th, not 31st.
    # The current simple approach is generally acceptable.
    # For more precise "day of month" sticking, one might do:
    # desired_day = base_date.day
    # current_date = base_date
    # loop do
    #   current_date += 1.month
    #   break if current_date.day == desired_day || current_date.end_of_month.day < desired_day
    # end
    # return current_date
    next_month_date
  end
end
