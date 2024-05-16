require "test_helper"

class Import::FieldTest < ActiveSupport::TestCase
  test "key is always a string" do
    field1 = Import::Field.new label: "Test", key: "test"
    field2 = Import::Field.new label: "Test2", key: :test2

    assert_equal "test", field1.key
    assert_equal "test2", field2.key
  end

  test "can set and override a validator for a field" do
    field = Import::Field.new \
      label: "Test",
      key: "Test",
      validator: ->(val) { val == 42 }

    assert field.validate(42)
    assert_not field.validate(41)

    field.define_validator do |value|
      value == 100
    end

    assert field.validate(100)
    assert_not field.validate(42)
  end
end
