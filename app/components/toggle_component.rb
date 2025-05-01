class ToggleComponent < ViewComponent::Base
  attr_reader :id, :name, :checked, :disabled, :checked_value, :unchecked_value, :opts

  def initialize(id:, name: nil, checked: false, disabled: false, checked_value: "1", unchecked_value: "0", **opts)
    @id = id
    @name = name
    @checked = checked
    @disabled = disabled
    @checked_value = checked_value
    @unchecked_value = unchecked_value
    @opts = opts
  end

  def label_classes
    class_names(
       "block w-9 h-5 cursor-pointer",
       "rounded-full bg-gray-100 theme-dark:bg-gray-700",
       "transition-colors duration-300",
       "after:content-[''] after:block after:bg-white after:absolute after:rounded-full",
       "after:top-0.5 after:left-0.5 after:w-4 after:h-4",
       "after:transition-transform after:duration-300 after:ease-in-out",
       "peer-checked:bg-green-600 peer-checked:after:translate-x-4",
       "peer-disabled:opacity-70 peer-disabled:cursor-not-allowed"
    )
  end
end
