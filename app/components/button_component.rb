# frozen_string_literal: true

class ButtonComponent < ButtonishComponent
  attr_reader :confirm

  def initialize(confirm: nil, **opts)
    super(**opts)
    @confirm = confirm
  end

  def container(&block)
    if href.present?
      button_to(href, **merged_opts, &block)
    else
      content_tag(:button, **merged_opts, &block)
    end
  end

  private
    def merged_opts
      merged_opts = opts.dup || {}
      extra_classes = merged_opts.delete(:class)
      href = merged_opts.delete(:href)
      data = merged_opts.delete(:data) || {}

      if confirm.present?
        data = data.merge(turbo_confirm: confirm.to_data_attribute)
      end

      merged_opts.merge(
        class: class_names(container_classes, extra_classes),
        data: data
      )
    end
end
