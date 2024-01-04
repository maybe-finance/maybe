class GenerateCategoricalMetricsJob
  include Sidekiq::Job

  def perform(family_id)
    family = Family.find(family_id)

    # Get all transactions for the family
    transactions = family.transactions

    # Group all transactions by enrichement_label and date
    transactions_by_label = transactions.group_by { |transaction| [transaction.enrichment_label, transaction.date] }

    # Iterate over each group, the first element of the group is an array with the label and the date, the second element is an array of transactions
    transactions_by_label.each do |details, transactions|
      # Get the label and date from the first element of the group
      label = details.first
      date = details.second

      # Get the sum of all transactions in the group
      amount = transactions.sum(&:amount)

      # Create a categorical_spending metric for the label and date
      Metric.find_or_create_by!(kind: 'categorical_spending', subkind: label, family: family, date: date).update(amount: amount)
    end


    # Create monthly roundup by enrichement_label using the categorical_spending metric
    Metric.where(kind: 'categorical_spending', family: family).group_by { |metric| [metric.subkind, metric.date.end_of_month] }.each do |label, metrics|
      amount = metrics.sum(&:amount)

      Metric.find_or_create_by(kind: 'categorical_spending_monthly', subkind: label.first, family: family, date: label.second).update(amount: amount)
    end
  end
end
