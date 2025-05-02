class Tabs::PanelComponent < ViewComponent::Base
  attr_reader :tab_id

  def initialize(tab_id:)
    @tab_id = tab_id
  end

  def call
    content
  end
end
