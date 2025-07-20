class DS::Tabs::Panel < DesignSystemComponent
  attr_reader :tab_id

  def initialize(tab_id:)
    @tab_id = tab_id
  end

  def call
    content
  end
end
