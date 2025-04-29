class DisclosureComponent < ViewComponent::Base
  renders_one :summary_content

  attr_reader :title, :align, :open, :opts

  def initialize(title:, align: "right", open: false, **opts)
    @title = title
    @align = align.to_sym
    @open = open
    @opts = opts
  end
end
