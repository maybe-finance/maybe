class Account::Group
  attr_reader :name, :type, :total_value, :percentage_held, :param

  def initialize(type:, total_value:, percentage_held:)
    @name = type.model_name.human
    @type = type
    @total_value = total_value
    @param = type.model_name.param_key.gsub("_", "-")
    @percentage_held = percentage_held
  end
end
