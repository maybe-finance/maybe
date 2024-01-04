module HoldingsHelper
  def holding_logo(security, size = 10, rounded_size = nil)
    rounded_size ||= size < 10 ? 'rounded-full' : 'rounded-xl'
    padding = size < 10 ? 1 : 2

    return get_svg_logo(security, size, rounded_size, padding) if security.logo_svg.present?
    return get_polygon_logo(security, size, rounded_size, padding) if security.logo.present? && security.logo_source == 'polygon'
    return get_image_logo(security, size, rounded_size) if security.logo.present?
    
    get_text_logo(security, size, rounded_size, padding)
  end

  def get_svg_logo(security, size, rounded_size, padding)
    logo = process_svg(security.logo_svg)
    raw "<div class='flex items-center justify-center w-#{size} h-#{size} #{rounded_size}' style='background-color:#{security.logo_colors['color1']}'><div class='p-#{padding + 1}'>#{logo}</div></div>"
  end
  
  def get_polygon_logo(security, size, rounded_size, padding)
    logo = image_tag("#{security.logo}?apiKey=#{ENV['POLYGON_KEY']}", class: 'object-contain w-full h-full')
    raw "<div class='flex items-center justify-center bg-gray-200 w-#{size} h-#{size} #{rounded_size}'><div class='p-#{padding}'>#{logo}</div></div>"
  end
  
  def get_image_logo(security, size, rounded_size)
    logo = image_tag(security.logo, class: 'object-contain w-full h-full')
    raw "<div class='flex items-center justify-center overflow-clip bg-gray-200 w-#{size} h-#{size} #{rounded_size}'>#{logo}</div>"
  end
  
  def get_text_logo(security, size, rounded_size, padding)
    raw "<span class='flex items-center justify-center w-#{size} h-#{size} text-2xs text-center font-bold text-gray-400 bg-gray-200 #{rounded_size}'><div class='p-#{padding}'>#{security.symbol}</div></span>"
  end

  def process_svg(svg)
    svg.gsub(/<svg /, '<svg class="w-full h-full" ')
  end
end