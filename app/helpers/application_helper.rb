module ApplicationHelper
  def title(page_title)
    content_for(:title) { page_title }
  end

  def header_title(page_title)
    content_for(:header_title) { page_title }
  end

  def description(page_description)
    content_for(:description) { page_description }
  end

  def meta_image(meta_image)
    content_for(:meta_image) { meta_image }
  end

  def header_content(&block)
    content_for(:header_content, &block)
  end

  def header_content?
    content_for?(:header_content)
  end

  def header_action(&block)
    content_for(:header_action, &block)
  end

  def header_action?
    content_for?(:header_action)
  end

  def abbreviated_currency(amount)
    number_to_currency number_to_human(amount, precision: 3, format: '%n%u', units: { unit: '', thousand: 'k', million: 'm', billion: 'b', trillion: 't' })
  end

  def gravatar(user, size: 180)
    gravatar_id = Digest::MD5::hexdigest(user.email.downcase)
    gravatar_url = "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}"
    gravatar_url
  end

  def markdown(text)
    @@parser ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML, tables: true)

    @@parser.render(text).html_safe
  end

  def mobile?
    request.user_agent.include?('MaybeiOS')
  end

  def institution_avatar(connection)
    if connection.institution.present? && connection.institution.url.present?
      website_domain = URI.parse(connection.institution.url).host
      img_str = "https://logo.clearbit.com/#{website_domain}"
      
      image_tag(img_str, class: 'w-10 h-10 mr-2 rounded-xl')
    else
      "<span class='flex w-10 h-10 shrink-0 grow-0 items-center justify-center rounded-xl bg-[#EAF4FF] mr-2'>
        <i class='fa-regular fa-building-columns text-[#3492FB] text-base'></i>
      </span>".html_safe
    end
  end

  def timeago(date, format: :long)
    return if date.blank?

    content = I18n.l(date, format: format)

    tag.time(content,
              title: content,
              data: {
                controller: 'timeago',
                timeago_refresh_interval_value: 30000,
                timeago_datetime_value: date.iso8601
              })
  end
end
