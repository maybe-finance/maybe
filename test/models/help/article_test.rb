require "test_helper"

class Help::ArticleTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    Help::Article.stubs(:root_path).returns(Rails.root.join("test", "fixtures", "files"))
  end

  test "returns nil if article not found" do
    assert_nil Help::Article.find("missing")
  end

  test "find and renders markdown article" do
    article = Help::Article.find("placeholder")

    assert_equal "Placeholder", article.title
    assert_equal "Test help article", article.content
    assert_equal "<p>Test help article</p>\n", article.html
  end
end
