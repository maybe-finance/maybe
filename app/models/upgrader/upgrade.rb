class Upgrader::Upgrade
  attr_reader :type, :commit_sha, :version, :url

  def initialize(type, data)
    @type = %w[release commit].include?(type) ? type : raise(ArgumentError, "Type must be either 'release' or 'commit'")
    @commit_sha = data[:commit_sha]
    @version = normalize_version(data[:version])
    @url = data[:url]
  end

  def complete?
    commit_sha == Maybe.commit_sha
  end

  def available?
    return false if commit_sha == Maybe.commit_sha || version < Maybe.version
    return false if version == Maybe.version && type == "release"
    true
  end

  def to_s
    type == "release" ? version.to_release_tag : "#{commit_sha.first(7)} (pre-release)"
  end

  private
    def normalize_version(version)
      version.is_a?(Semver) ? version : Semver.new(version)
    end
end
