class Upgrader::Upgrade
  attr_reader :type, :commit_sha, :version, :url

  def initialize(type, data)
    @type = %w[release commit].include?(type) ? type : raise(ArgumentError, "Type must be either 'release' or 'commit'")
    @commit_sha = data[:commit_sha]
    @version = data[:version]
    @url = data[:url]
  end
end
