# Dynamic settings the user can change within the app (helpful for self-hosting)
class Setting < RailsSettings::Base
  cache_prefix { "v1" }

  field :render_deploy_hook,
        type: :string,
        default: ENV["RENDER_DEPLOY_HOOK"],
        validates: { allow_blank: true, format: { with: /\Ahttps:\/\/api\.render\.com\/deploy\/srv-.+\z/ } }

  field :upgrades_mode,
        type: :string,
        default: ENV.fetch("UPGRADES_MODE", "manual"),
        validates: { inclusion: { in: %w[manual auto] } }

  field :upgrades_target,
        type: :string,
        default: ENV.fetch("UPGRADES_TARGET", "release"),
        validates: { inclusion: { in: %w[release commit] } }

  field :data_enrichment_enabled,
        type: :boolean,
        default: false

  field :synth_api_key, type: :string, default: ENV["SYNTH_API_KEY"]

  field :require_invite_for_signup, type: :boolean, default: false
end
