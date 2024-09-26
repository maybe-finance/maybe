require "test_helper"

class Import::MappingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)

    @import = imports(:transaction)
  end

  test "creates resource mapping" do
    category = categories(:food_and_drink)

    post import_mappings_path(@import), params: {
      import_mapping: {
        type: "Import::CategoryMapping",
        mappable_type: "Category",
        mappable_id: category.id,
        key: "Food"
      }
    }

    mapping = @import.mappings.order(:created_at).last

    assert_equal category, mapping.mappable
    assert_redirected_to import_confirm_path(@import)
  end

  test "resource mapping can create new resource" do
    category = categories(:food_and_drink)

    post import_mappings_path(@import), params: {
      import_mapping: {
        type: "Import::CategoryMapping",
        mappable_type: "Category",
        mappable_id: "internal_new",
        key: "Food"
      }
    }

    mapping = @import.mappings.order(:created_at).last

    assert_nil mapping.mappable
    assert mapping.create_when_empty
    assert_redirected_to import_confirm_path(@import)
  end

  test "creates value mapping" do
    post import_mappings_path(@import), params: {
      import_mapping: {
        type: "Import::AccountTypeMapping",
        key: "Checking",
        value: "Depository"
      }
    }

    mapping = @import.mappings.order(:created_at).last

    assert_nil mapping.mappable
    assert_instance_of Depository, mapping.accountable
    assert_redirected_to import_confirm_path(@import)
  end

  test "updates mapping" do
    mapping = import_mappings(:one)
    new_category = categories(:income)

    patch import_mapping_path(@import, mapping), params: {
      import_mapping: {
        mappable_type: "Category",
        mappable_id: new_category.id,
        key: "Food"
      }
    }

    mapping.reload

    assert_equal new_category, mapping.mappable
    assert_equal "Food", mapping.key

    assert_redirected_to import_confirm_path(@import)
  end
end
