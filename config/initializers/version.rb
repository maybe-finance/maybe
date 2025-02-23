module Maybe
  class << self
    def version
      Semver.new(semver)
    end

    def commit_sha
      `git rev-parse HEAD`.chomp rescue nil
    end

    private
      def semver
        "0.4.1"
      end
  end
end
