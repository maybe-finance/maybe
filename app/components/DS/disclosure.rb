class DS::Disclosure < DesignSystemComponent
  renders_one :summary_content

  attr_reader :title, :align, :open, :opts

  def initialize(title: nil, align: "right", open: false, **opts)
    @title = title
    @align = align.to_sym
    @open = open
    @opts = opts
  end
end
