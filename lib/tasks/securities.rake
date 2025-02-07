# frozen_string_literal: true

namespace :securities do
  desc "Backfill exchange_operating_mic for securities using Synth API"
  task backfill_exchange_mic: :environment do
    puts "Starting exchange_operating_mic backfill..."

    api_key = Rails.application.config.app_mode.self_hosted? ? Setting.synth_api_key : ENV["SYNTH_API_KEY"]
    unless api_key.present?
      puts "ERROR: No Synth API key found. Please set SYNTH_API_KEY env var or configure it in Settings for self-hosted mode."
      exit 1
    end

    securities = Security.where(exchange_operating_mic: nil).where.not(ticker: nil)
    total = securities.count
    processed = 0
    errors = []

    securities.find_each do |security|
      processed += 1
      print "\rProcessing #{processed}/#{total} (#{(processed.to_f/total * 100).round(1)}%)"

      begin
        response = Faraday.get("https://api.synthfinance.com/tickers/#{security.ticker}") do |req|
          req.params["country_code"] = security.country_code if security.country_code.present?
          req.headers["Authorization"] = "Bearer #{api_key}"
        end

        if response.success?
          data = JSON.parse(response.body).dig("data")
          exchange_data = data["exchange"]

          # Update security with exchange info and other metadata
          security.update!(
            exchange_operating_mic: exchange_data["operating_mic_code"],
            exchange_mic: exchange_data["mic_code"],
            exchange_acronym: exchange_data["acronym"],
            name: data["name"],
            logo_url: data["logo_url"],
            country_code: exchange_data["country_code"]
          )
        else
          errors << "#{security.ticker}: HTTP #{response.status} - #{response.body}"
        end
      rescue => e
        errors << "#{security.ticker}: #{e.message}"
      end

      # Add a small delay to not overwhelm the API
      sleep(0.1)
    end

    puts "\n\nBackfill complete!"
    puts "Processed #{processed} securities"

    if errors.any?
      puts "\nErrors encountered:"
      errors.each { |error| puts "  - #{error}" }
    end
  end

  desc "De-duplicate securities based on ticker + exchange_operating_mic"
  task :deduplicate, [ :dry_run ] => :environment do |_t, args|
    # First check if we have any securities without exchange_operating_mic
    missing_mic_count = Security.where(exchange_operating_mic: nil).where.not(ticker: nil).count

    if missing_mic_count > 0
      puts "ERROR: Found #{missing_mic_count} securities without exchange_operating_mic."
      puts "Please run 'rails securities:backfill_exchange_mic' first to ensure all securities have exchange_operating_mic values."
      exit 1
    end

    dry_run = args[:dry_run].present?
    puts "Starting securities de-duplication... #{dry_run ? '(DRY RUN)' : ''}"

    # Find all duplicate securities (same ticker + exchange_operating_mic)
    duplicates = Security
      .where.not(ticker: nil)
      .where.not(exchange_operating_mic: nil)
      .group(:ticker, :exchange_operating_mic)
      .having("COUNT(*) > 1")
      .pluck(:ticker, :exchange_operating_mic)

    puts "Found #{duplicates.length} sets of duplicate securities"
    total_holdings = 0
    total_trades = 0
    total_prices = 0

    duplicates.each do |ticker, exchange_operating_mic|
      securities = Security.where(ticker: ticker, exchange_operating_mic: exchange_operating_mic)
        .order(created_at: :asc)

      canonical = securities.first
      duplicates = securities[1..]

      puts "\nProcessing #{ticker} (#{exchange_operating_mic}):"
      puts "  Canonical: #{canonical.id} (created: #{canonical.created_at})"
      puts "  Duplicates: #{duplicates.map(&:id).join(', ')}"

      # Count affected records
      holdings_count = Account::Holding.where(security_id: duplicates).count
      trades_count = Account::Trade.where(security_id: duplicates).count
      prices_count = Security::Price.where(security_id: duplicates).count

      total_holdings += holdings_count
      total_trades += trades_count
      total_prices += prices_count

      puts "  Would update:"
      puts "    - #{holdings_count} holdings"
      puts "    - #{trades_count} trades"
      puts "    - #{prices_count} prices"

      unless dry_run
        begin
          ActiveRecord::Base.transaction do
            # Update all references to point to the canonical security
            Account::Holding.where(security_id: duplicates).update_all(security_id: canonical.id)
            Account::Trade.where(security_id: duplicates).update_all(security_id: canonical.id)
            Security::Price.where(security_id: duplicates).update_all(security_id: canonical.id)

            # Delete the duplicates
            duplicates.each(&:destroy!)
          end
          puts "  ✓ Successfully merged and removed duplicates"
        rescue => e
          puts "  ✗ Error processing #{ticker}: #{e.message}"
        end
      end
    end

    puts "\nSummary:"
    puts "  Total duplicate sets: #{duplicates.length}"
    puts "  Total affected records:"
    puts "    - #{total_holdings} holdings"
    puts "    - #{total_trades} trades"
    puts "    - #{total_prices} prices"
    puts "  Mode: #{dry_run ? 'Dry run (no changes made)' : 'Live run (changes applied)'}"
    puts "\nDe-duplication complete!"
  end
end
