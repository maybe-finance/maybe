class Help::Article
  attr_reader :frontmatter, :content

  def initialize(frontmatter:, content:)
    @frontmatter = frontmatter
    @content = content
  end

  def title
    frontmatter["title"]
  end

  def html
    render_markdown(content)
  end

  class << self
    def root_path
      Rails.root.join("docs", "help")
    end

    def find(slug)
      Dir.glob(File.join(root_path, "*.md")).each do |file_path|
        file_content = File.read(file_path)
        frontmatter, markdown_content = parse_frontmatter(file_content)

        return new(frontmatter:, content: markdown_content) if frontmatter["slug"] == slug
      end

      nil
    end

    private

      def parse_frontmatter(content)
        if content =~ /\A---(.+?)---/m
          frontmatter = YAML.safe_load($1)
          markdown_content = content[($~.end(0))..-1].strip
        else
          frontmatter = {}
          markdown_content = content
        end

        [ frontmatter, markdown_content ]
      end
  end

  private

    def render_markdown(content)
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
      markdown.render(content)
    end
end
