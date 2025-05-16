class Provider::SimpleFin
  attr_reader :client, :region

  # Error subclasses
  Error = Class.new(Provider::Error)
  RateLimitExceededError = Class.new(Error)

  # SimpleFIN only supports these account types
  MAYBE_SUPPORTED_SIMPLE_FIN_PRODUCTS = %w[Depository Investment Loan CreditCard].freeze

  class << self
    # Helper class method to access the SimpleFin specific configuration
    def provider_config
      Rails.application.config.simple_fin
    end
  end

  def initialize(config, region: :us)
    @region = region
    @is_supported_api = is_supported_api()
  end

  ##
  # Verifies that SimpleFIN is available for use with these parameters
  #
  # @param [string] user_id
  # @param [string] accountable_type The account type that we are checking
  def is_available(user_id, accountable_type)
    # Verify we have support for this accountable type
    is_supported_account_type = MAYBE_SUPPORTED_SIMPLE_FIN_PRODUCTS.include?(accountable_type)
    return false unless is_supported_account_type

    # Verify it is configured
    config = Provider::SimpleFin.provider_config
    return false unless config.present?

    # Make sure this API version is supported
    is_supported_api = @is_supported_api

    is_supported_api
  end

  ##
  # Sends a request to the SimpleFIN endpoint
  #
  # @param [Boolean] include_creds Controls if credentials should be included or if this request should be anonymous. Default true.
  def send_request_to_sf(path, include_creds = true)
    # Grab access URL from the env
    config = Provider::SimpleFin.provider_config
    access_url = config.access_url
    # Add the access URL to the path
    uri = URI.parse(access_url + path)
    # Setup the request
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https") # Enable SSL if the scheme is https
    request = Net::HTTP::Get.new(uri.request_uri)
    if include_creds && uri.user && uri.password
      request.basic_auth(uri.user, uri.password)
    end

    # Send the request
    begin
      response = http.request(request)
      if response.is_a?(Net::HTTPSuccess)
        parsed_data = JSON.parse(response.body)
        # Check for errors from the API
        if parsed_data.key?("errors") && parsed_data["errors"].is_a?(Array) && !parsed_data["errors"].empty?
          error_messages = parsed_data["errors"].join(", ")
          Rails.logger.error("SimpleFIN API returned errors for #{uri.host}#{uri.path}: #{error_messages}")
        end
        parsed_data
      else
        # Handle HTTP non-success (4xx, 5xx errors)
        body_summary = response.body.to_s.truncate(500)
        Rails.logger.error("SimpleFIN HTTP Request Failed for #{uri.host}#{uri.path}. Status: #{response.code} #{response.message}. Body: #{body_summary}")
        raise "SimpleFIN HTTP Request Failed: #{response.code} #{response.message}. Body: #{body_summary}"
      end
    end
  end

  ##
  # Sends a request to get all available accounts from SimpleFIN
  #
  # @param [str] accountable_type The name of the account type we're looking for.
  # @param [int?] trans_start_date A linux epoch of the start date to get transactions of.
  # @param [int?] trans_end_date A linux epoch of the end date to get transactions between.
  # @param [Boolean] trans_pending If we should include pending transactions. Default is true.
  def get_available_accounts(accountable_type, trans_start_date = nil, trans_end_date = nil, trans_pending = true)
    check_rate_limit
    endpoint = "/accounts?pending=#{trans_pending}"

    # Add any parameters we care about
    if trans_start_date
      endpoint += "&trans_start_date=#{trans_start_date}"
    end
    if trans_end_date
      endpoint += "&trans_end_date=#{trans_end_date}"
    end

    # account_info = send_request_to_sf(endpoint)
    # accounts = account_info["accounts"]
    # TODO: Remove JSON Reading for real requests. Disabled currently due to preventing rate limits.
    json_file_path =  Rails.root.join("sample.simple.fin.json")
    accounts = []
    error_messages = []
    if File.exist?(json_file_path)
      file_content = File.read(json_file_path)
      parsed_json = JSON.parse(file_content)
      accounts = parsed_json["accounts"] || []
      error_messages = parsed_json["errors"] || []
    else
      Rails.logger.warn "SimpleFIN: Sample JSON file not found at #{json_file_path}. Returning empty accounts."
    end


    # The only way we can really determine types right now is by some properties. Try and set their types
    accounts.each do |account|
      # Accounts can be considered Investment accounts if they have any holdings associated to them
      if account.key?("holdings") && account["holdings"].is_a?(Array) && !account["holdings"].empty?
        account["type"] = "Investment"
      elsif account["balance"].to_d <= 0 && account["name"]&.downcase&.include?("card")
        account["type"] = "CreditCard"
      elsif account["balance"].to_d.negative? # Could be loan or credit card
        account["type"] = "Loan" # Default for negative balance if not clearly a card
      else
        account["type"] = "Depository" # Default for positive balance
      end

      # Set error messages if related
      account["org"]["institution_errors"] = []
      error_messages.each do |error|
        if error.include? account["org"]["name"]
          account["org"]["institution_errors"].push(error)
        end
      end
    end

    if accountable_type == nil
      accounts
    else
      # Update accounts to only include relevant accounts to the type
      accounts.filter { |acc|  acc["type"] == accountable_type }
    end
  end

  ##
  # Increments the call count for tracking rate limiting of SimpleFIN.
  #
  # @raises [RateLimitExceededError] if the daily API call limit has been reached.
  def check_rate_limit
    today = Date.current
    # Find or initialize the rate limit record for the family for today
    rate_limit_record = SimpleFinRateLimit.find_or_initialize_by(date: today)

    # Determine the actual limit: from config
    limit = Provider::SimpleFin.provider_config.rate_limit

    if rate_limit_record.call_count >= limit
      raise RateLimitExceededError, "SimpleFIN API daily rate limit exceeded. Limit: #{limit} calls."
    end

    # Increment the call count for today. This also saves the record if new or updates if existing.
    rate_limit_record.update!(call_count: rate_limit_record.call_count + 1)
  end

  # Returns if this is a supported API of SimpleFIN by the access url in the config.
  def is_supported_api
    # Make sure the config is loaded since this is called early
    config = Provider::SimpleFin.provider_config
    return false unless config.present?

    get_api_versions().include?("1.0")
  end

  # Returns the API versions currently supported by the given SimpleFIN access url.
  def get_api_versions
    ver_info = send_request_to_sf("/info", false)
    ver_info["versions"]
  end
end
