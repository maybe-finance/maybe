class IncomeStatement::FamilyStats
  include IncomeStatement::BaseQuery

  def initialize(family, interval: "month")
    @family = family
    @interval = interval
  end

  def call
    ActiveRecord::Base.connection.select_all(query_sql).map do |row|
      StatRow.new(
        classification: row["classification"],
        median: row["median"],
        avg: row["avg"],
        missing_exchange_rates?: row["missing_exchange_rates"]
      )
    end
  end

  private
    StatRow = Data.define(:classification, :median, :avg, :missing_exchange_rates?)

    def query_sql
      base_sql = base_query_sql(family: @family, interval: @interval, transactions_scope: @family.transactions.active)

      <<~SQL
        WITH base_totals AS (
          #{base_sql}
        ), aggregated_totals AS (
          SELECT
            date,
            classification,
            SUM(total) as total,
            BOOL_OR(missing_exchange_rates) as missing_exchange_rates
          FROM base_totals
          GROUP BY date, classification
        )
        SELECT
            classification,
            ABS(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total)) as median,
            ABS(AVG(total)) as avg,
            BOOL_OR(missing_exchange_rates) as missing_exchange_rates
        FROM aggregated_totals
        GROUP BY classification;
      SQL
    end
end
