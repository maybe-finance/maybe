require "zip"
require "csv"

class Family::DataExporter
  def initialize(family)
    @family = family
  end

  def generate_export
    # Create a StringIO to hold the zip data in memory
    zip_data = Zip::OutputStream.write_buffer do |zipfile|
      # Add accounts.csv
      zipfile.put_next_entry("accounts.csv")
      zipfile.write generate_accounts_csv

      # Add transactions.csv
      zipfile.put_next_entry("transactions.csv")
      zipfile.write generate_transactions_csv

      # Add trades.csv
      zipfile.put_next_entry("trades.csv")
      zipfile.write generate_trades_csv

      # Add categories.csv
      zipfile.put_next_entry("categories.csv")
      zipfile.write generate_categories_csv

      # Add all.ndjson
      zipfile.put_next_entry("all.ndjson")
      zipfile.write generate_ndjson
    end

    # Rewind and return the StringIO
    zip_data.rewind
    zip_data
  end

  private

    def generate_accounts_csv
      CSV.generate do |csv|
        csv << [ "id", "name", "type", "subtype", "balance", "currency", "created_at" ]

        # Only export accounts belonging to this family
        @family.accounts.includes(:accountable).find_each do |account|
          csv << [
            account.id,
            account.name,
            account.accountable_type,
            account.subtype,
            account.balance.to_s,
            account.currency,
            account.created_at.iso8601
          ]
        end
      end
    end

    def generate_transactions_csv
      CSV.generate do |csv|
        csv << [ "date", "account_name", "amount", "name", "category", "tags", "notes", "currency" ]

        # Only export transactions from accounts belonging to this family
        @family.transactions
          .includes(:category, :tags, entry: :account)
          .find_each do |transaction|
            csv << [
              transaction.entry.date.iso8601,
              transaction.entry.account.name,
              transaction.entry.amount.to_s,
              transaction.entry.name,
              transaction.category&.name,
              transaction.tags.pluck(:name).join(","),
              transaction.entry.notes,
              transaction.entry.currency
            ]
          end
      end
    end

    def generate_trades_csv
      CSV.generate do |csv|
        csv << [ "date", "account_name", "ticker", "quantity", "price", "amount", "currency" ]

        # Only export trades from accounts belonging to this family
        @family.trades
          .includes(:security, entry: :account)
          .find_each do |trade|
            csv << [
              trade.entry.date.iso8601,
              trade.entry.account.name,
              trade.security.ticker,
              trade.qty.to_s,
              trade.price.to_s,
              trade.entry.amount.to_s,
              trade.currency
            ]
          end
      end
    end

    def generate_categories_csv
      CSV.generate do |csv|
        csv << [ "name", "color", "parent_category", "classification" ]

        # Only export categories belonging to this family
        @family.categories.includes(:parent).find_each do |category|
          csv << [
            category.name,
            category.color,
            category.parent&.name,
            category.classification
          ]
        end
      end
    end

    def generate_ndjson
      lines = []

      # Export accounts with full accountable data
      @family.accounts.includes(:accountable).find_each do |account|
        lines << {
          type: "Account",
          data: account.as_json(
            include: {
              accountable: {}
            }
          )
        }.to_json
      end

      # Export categories
      @family.categories.find_each do |category|
        lines << {
          type: "Category",
          data: category.as_json
        }.to_json
      end

      # Export tags
      @family.tags.find_each do |tag|
        lines << {
          type: "Tag",
          data: tag.as_json
        }.to_json
      end

      # Export merchants (only family merchants)
      @family.merchants.find_each do |merchant|
        lines << {
          type: "Merchant",
          data: merchant.as_json
        }.to_json
      end

      # Export transactions with full data
      @family.transactions.includes(:category, :merchant, :tags, entry: :account).find_each do |transaction|
        lines << {
          type: "Transaction",
          data: {
            id: transaction.id,
            entry_id: transaction.entry.id,
            account_id: transaction.entry.account_id,
            date: transaction.entry.date,
            amount: transaction.entry.amount,
            currency: transaction.entry.currency,
            name: transaction.entry.name,
            notes: transaction.entry.notes,
            excluded: transaction.entry.excluded,
            category_id: transaction.category_id,
            merchant_id: transaction.merchant_id,
            tag_ids: transaction.tag_ids,
            kind: transaction.kind,
            created_at: transaction.created_at,
            updated_at: transaction.updated_at
          }
        }.to_json
      end

      # Export trades with full data
      @family.trades.includes(:security, entry: :account).find_each do |trade|
        lines << {
          type: "Trade",
          data: {
            id: trade.id,
            entry_id: trade.entry.id,
            account_id: trade.entry.account_id,
            security_id: trade.security_id,
            ticker: trade.security.ticker,
            date: trade.entry.date,
            qty: trade.qty,
            price: trade.price,
            amount: trade.entry.amount,
            currency: trade.currency,
            created_at: trade.created_at,
            updated_at: trade.updated_at
          }
        }.to_json
      end

      # Export valuations
      @family.entries.valuations.includes(:account, :entryable).find_each do |entry|
        lines << {
          type: "Valuation",
          data: {
            id: entry.entryable.id,
            entry_id: entry.id,
            account_id: entry.account_id,
            date: entry.date,
            amount: entry.amount,
            currency: entry.currency,
            name: entry.name,
            created_at: entry.created_at,
            updated_at: entry.updated_at
          }
        }.to_json
      end

      # Export budgets
      @family.budgets.find_each do |budget|
        lines << {
          type: "Budget",
          data: budget.as_json
        }.to_json
      end

      # Export budget categories
      @family.budget_categories.includes(:budget, :category).find_each do |budget_category|
        lines << {
          type: "BudgetCategory",
          data: budget_category.as_json
        }.to_json
      end

      lines.join("\n")
    end
end
