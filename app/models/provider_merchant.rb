class ProviderMerchant < Merchant
  enum source: { plaid: "plaid", synth: "synth" }

  validates :name, uniqueness: { scope: :source }
end
