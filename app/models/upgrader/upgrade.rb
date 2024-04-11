class Upgrader::Upgrade
  attr_reader :type, :commit_sha, :version, :url

  def initialize(type, data)
    @type = %w[release commit].include?(type) ? type : raise(ArgumentError, "Type must be either 'release' or 'commit'")
    @commit_sha = data[:commit_sha]
    @version = data[:version]
    @url = data[:url]
  end

  def complete?
    commit_sha == Maybe.commit_sha
  end

  def available?
    version > Maybe.version || (version == Maybe.version && commit_sha != Maybe.commit_sha)
  end
end
