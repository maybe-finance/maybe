# Dynamic settings the user can change within the app (helpful for self-hosting)
class Setting < RailsSettings::Base
  cache_prefix { "v1" }

  field :render_deploy_hook,
        type: :string,
        default: ENV["RENDER_DEPLOY_HOOK"],
        validates: { allow_blank: true, format: { with: /\Ahttps:\/\/api\.render\.com\/deploy\/srv-.+\z/ } }

  field :auto_upgrades_mode,
        type: :string,
        default: ENV["SELF_HOSTING_AUTO_UPGRADES_MODE"] || "disabled",
        validates: { inclusion: { in: %w[disabled release commit] } }
end
