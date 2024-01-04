class SyncPropertyValuesJob
  include Sidekiq::Job

  def perform(account_id)
    account = Account.find(account_id)

    # Check if auto_valuation is enabled and that current_balance_date is either nil or over 30 days old
    if account.auto_valuation && (account.current_balance_date.nil? || account.current_balance_date < 30.days.ago)
      url_formatted_address = "#{account.property_details['line_1'].gsub(' ','-')}-#{account.property_details['city']}-#{account.property_details['state_abbreviation']}-#{account.property_details['zip_code']}_rb"
      scraper = Faraday.get("https://app.scrapingbee.com/api/v1/?api_key=#{ENV['SCRAPING_BEE_KEY']}&url=https%3A%2F%2Fwww.zillow.com%2Fhomes%2F#{url_formatted_address}%2F&render_js=false&extract_rules=%7B%22value%22%3A'%2F%2Fspan%5B%40data-testid%3D%22zestimate-text%22%5D%2Fspan%2Fspan'%7D")
      
      # If the scraper returns a 200 status code, parse the response body and update the account
      if scraper.status == 200 and JSON.parse(scraper.body)['value'].present?
        account.update(current_balance: JSON.parse(scraper.body)['value'].gsub('$','').gsub(',','').to_i, current_balance_date: Date.today)
      end
    end
  end
end