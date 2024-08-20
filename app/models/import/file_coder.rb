class Import::FileCoder
  def self.load(payload)
    return nil unless payload.is_a?(String)

    if Base64.encode64(Base64.decode64(payload)) == payload
      Base64.decode64(payload)
    else
      # backwards compatibility allow load raw data from db
      payload
    end
  end

  def self.dump(payload)
    Base64.encode64(payload)
  end
end
