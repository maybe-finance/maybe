class SyncSecurityDetailsJob
  include Sidekiq::Job

  def perform(security_id)
    security = Security.find_by(id: security_id)
    return unless security

    update_security_details(security)
    update_security_logo(security)
  end

  private

  def update_security_details(security)
    details = fetch_twelvedata_details(security.symbol)
    return unless details

    website = extract_website(details)
    security.update(
      industry: details['industry'],
      sector: details['sector'],
      website: website
    )
  end

  def fetch_twelvedata_details(symbol)
    response = Faraday.get("https://api.twelvedata.com/profile?symbol=#{symbol}&apikey=#{ENV['TWELVEDATA_KEY']}")
    JSON.parse(response.body)
  end

  def extract_website(details)
    return unless details['website'].present?

    URI.parse(details['website']).host.gsub('www.', '')
  end

  def update_security_logo(security)
    logo_url, logo_source = fetch_logo(security.symbol, security.website, security.name)
    security.update(logo: logo_url, logo_source: logo_source) if logo_url
  end

  def fetch_logo(symbol, website, name)
    logo_url, logo_source = fetch_polygon_logo(symbol)
    logo_url, logo_source = fetch_twelvedata_logo(symbol) unless logo_url
    logo_url, logo_source = fetch_clearbit_logo(website) unless logo_url
    logo_url, logo_source = fetch_gpt_clearbit_logo(symbol, name) unless logo_url

    [logo_url, logo_source]
  end

  def fetch_polygon_logo(symbol)
    response = Faraday.get("https://api.polygon.io/v3/reference/tickers/#{symbol}?apiKey=#{ENV['POLYGON_KEY']}")
    results = JSON.parse(response.body)['results']
    return unless results.present? && results['branding'].present?

    [results['branding']['logo_url'], 'polygon']
  end

  def fetch_twelvedata_logo(symbol)
    response = Faraday.get("https://api.twelvedata.com/logo?symbol=#{symbol}&apikey=#{ENV['TWELVEDATA_KEY']}")
    url = JSON.parse(response.body)['url']
    return unless url.present?

    [url, 'twelvedata']
  end

  def fetch_clearbit_logo(website)
    return unless website.present?

    ["https://logo.clearbit.com/#{website}", 'clearbit']
  end

  def fetch_gpt_clearbit_logo(symbol, security_name)
    openai = OpenAI::Client.new(access_token: ENV['OPENAI_ACCESS_TOKEN'])
    gpt_response = openai.chat(
      parameters: {
        model: "gpt-4",
        messages: [
          { role: "system", content: "You are tasked with finding the domain for a company. You are given the company name and the ticker symbol. You are given the following information:\n\nSecurity Name: #{security_name}\nSecurity Symbol: #{symbol}\n\nYou exclusively respond with only the domain and absolutely nothing else." },
          { role: "user", content: "What is the domain for this company?" },
        ],
        temperature: 0,
        max_tokens: 200
      }
    )

    domain = gpt_response.dig("choices", 0, "message", "content")
    return unless domain.present?

    ["https://logo.clearbit.com/#{domain}", 'clearbit']
  end
end