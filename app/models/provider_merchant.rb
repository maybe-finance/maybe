class ProviderMerchant < Merchant
  enum :source, { plaid: "plaid", synth: "synth", ai: "ai" }

  validates :name, uniqueness: { scope: [ :source, :website_url ] }
end
