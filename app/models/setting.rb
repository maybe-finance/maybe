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

  field :app_domain, type: :string, default: ENV["APP_DOMAIN"]
  field :email_sender, type: :string, default: ENV["EMAIL_SENDER"]

  field :synth_api_key, type: :string, default: ENV["SYNTH_API_KEY"]

  scope :smtp_settings do
    field :smtp_host, type: :string, read_only: true, default: ENV["SMTP_ADDRESS"]
    field :smtp_port, type: :string, read_only: true, default: ENV["SMTP_PORT"]
    field :smtp_username, type: :string, read_only: true, default: ENV["SMTP_USERNAME"]
    field :smtp_password, type: :string, read_only: true, default: ENV["SMTP_PASSWORD"]
  end

  def self.smtp_settings_populated?
    Setting.defined_fields.select { |f| f.scope == :smtp_settings }.map(&:read).all?(&:present?)
  end
end
