module MfaHelper
  def generate_mfa_qr_code(provisioning_uri)
    qr_code = RQRCode::QRCode.new(provisioning_uri).as_svg(
      color: "141414",
      module_size: 4,
      standalone: true,
      use_path: true,
      svg_attributes: {
        width: "240",
        height: "240",
        viewBox: "0 0 60 60"
      }
    )

    # Whitelist specific SVG attributes and elements that we know are safe
    sanitize qr_code,
      tags: %w[svg g path rect],
      attributes: %w[viewBox height width fill stroke stroke-width d x y class]
  end
end
