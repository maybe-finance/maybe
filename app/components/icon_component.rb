# frozen_string_literal: true

class IconComponent < ViewComponent::Base
  erb_template <<~ERB
    <%= tag.div class: container_classes do %>
      <%= lucide_icon(@icon, class: icon_classes) %>
    <% end %>
  ERB

  VARIANTS = {
    default: {
      icon: "fg-gray",
      container: "bg-transparent"
    },
    destructive: {
      icon: "text-destructive",
      container: "bg-transparent"
    }
  }

  SIZES = {
    sm: {
      icon: "w-4 h-4",
      container: "w-8 h-8"
    },
    md: {
      icon: "w-5 h-5",
      container: "w-10 h-10"
    },
    lg: {
      icon: "w-6 h-6",
      container: "w-12 h-12"
    }
  }

  def initialize(icon, variant: "default", size: "md")
    @icon = icon
    @variant = variant.to_sym
    @size = size.to_sym
  end

  def icon_classes
    [
      size_meta[:icon],
      variant_meta[:icon]
    ].join(" ")
  end

  def container_classes
    [
      "flex justify-center items-center",
      show_padding? ? size_meta[:container] : "",
      variant_meta[:container]
    ].join(" ")
  end

  private
    def show_padding?
      @variant != :default && @variant != :destructive
    end

    def variant_meta
      VARIANTS[@variant]
    end

    def size_meta
      SIZES[@size]
    end
end
