class TabComponent < ViewComponent::Base
  attr_reader :id, :label

  def initialize(id:, label:)
    @id = id
    @label = label
  end

  def call
    content
  end
end
