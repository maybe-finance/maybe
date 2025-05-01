class Tabs::NavComponent < ViewComponent::Base
  erb_template <<~ERB
    <%= tag.nav class: classes do %>
      <% btns.each do |btn| %>
        <%= btn %>
      <% end %>
    <% end %>
  ERB

  renders_many :btns, ->(id:, label:, classes: nil, &block) do
    content_tag(
      :button, label, id: id,
      type: "button",
      class: class_names(btn_classes, id == active_tab ? active_btn_classes : inactive_btn_classes, classes),
      data: { id: id, action: "tabs#show", tabs_target: "navBtn" },
      &block
    )
  end

  attr_reader :active_tab, :classes, :active_btn_classes, :inactive_btn_classes, :btn_classes

  def initialize(active_tab:, classes: nil, active_btn_classes: nil, inactive_btn_classes: nil, btn_classes: nil)
    @active_tab = active_tab
    @classes = classes
    @active_btn_classes = active_btn_classes
    @inactive_btn_classes = inactive_btn_classes
    @btn_classes = btn_classes
  end
end
