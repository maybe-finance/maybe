require "test_helper"

class Valuation::NameTest < ActiveSupport::TestCase
  # Opening anchor tests
  test "generates opening anchor name for Property" do
    name = Valuation::Name.new("opening_anchor", "Property")
    assert_equal "Original purchase price", name.to_s
  end

  test "generates opening anchor name for Loan" do
    name = Valuation::Name.new("opening_anchor", "Loan")
    assert_equal "Original principal", name.to_s
  end

  test "generates opening anchor name for Investment" do
    name = Valuation::Name.new("opening_anchor", "Investment")
    assert_equal "Opening account value", name.to_s
  end

  test "generates opening anchor name for Vehicle" do
    name = Valuation::Name.new("opening_anchor", "Vehicle")
    assert_equal "Original purchase price", name.to_s
  end

  test "generates opening anchor name for Crypto" do
    name = Valuation::Name.new("opening_anchor", "Crypto")
    assert_equal "Opening account value", name.to_s
  end

  test "generates opening anchor name for OtherAsset" do
    name = Valuation::Name.new("opening_anchor", "OtherAsset")
    assert_equal "Opening account value", name.to_s
  end

  test "generates opening anchor name for other account types" do
    name = Valuation::Name.new("opening_anchor", "Depository")
    assert_equal "Opening balance", name.to_s
  end

  # Current anchor tests
  test "generates current anchor name for Property" do
    name = Valuation::Name.new("current_anchor", "Property")
    assert_equal "Current market value", name.to_s
  end

  test "generates current anchor name for Loan" do
    name = Valuation::Name.new("current_anchor", "Loan")
    assert_equal "Current loan balance", name.to_s
  end

  test "generates current anchor name for Investment" do
    name = Valuation::Name.new("current_anchor", "Investment")
    assert_equal "Current account value", name.to_s
  end

  test "generates current anchor name for Vehicle" do
    name = Valuation::Name.new("current_anchor", "Vehicle")
    assert_equal "Current market value", name.to_s
  end

  test "generates current anchor name for Crypto" do
    name = Valuation::Name.new("current_anchor", "Crypto")
    assert_equal "Current account value", name.to_s
  end

  test "generates current anchor name for OtherAsset" do
    name = Valuation::Name.new("current_anchor", "OtherAsset")
    assert_equal "Current account value", name.to_s
  end

  test "generates current anchor name for other account types" do
    name = Valuation::Name.new("current_anchor", "Depository")
    assert_equal "Current balance", name.to_s
  end

  # Reconciliation tests
  test "generates recon name for Property" do
    name = Valuation::Name.new("reconciliation", "Property")
    assert_equal "Manual value update", name.to_s
  end

  test "generates recon name for Investment" do
    name = Valuation::Name.new("reconciliation", "Investment")
    assert_equal "Manual value update", name.to_s
  end

  test "generates recon name for Vehicle" do
    name = Valuation::Name.new("reconciliation", "Vehicle")
    assert_equal "Manual value update", name.to_s
  end

  test "generates recon name for Crypto" do
    name = Valuation::Name.new("reconciliation", "Crypto")
    assert_equal "Manual value update", name.to_s
  end

  test "generates recon name for OtherAsset" do
    name = Valuation::Name.new("reconciliation", "OtherAsset")
    assert_equal "Manual value update", name.to_s
  end

  test "generates recon name for Loan" do
    name = Valuation::Name.new("reconciliation", "Loan")
    assert_equal "Manual principal update", name.to_s
  end

  test "generates recon name for other account types" do
    name = Valuation::Name.new("reconciliation", "Depository")
    assert_equal "Manual balance update", name.to_s
  end
end
