require "test_helper"

class Help::ArticlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)

    @article = Help::Article.new(frontmatter: { title: "Test Article", slug: "test-article" }, content: "")

    Help::Article.stubs(:find).returns(@article)
  end

  test "can view help article" do
    get help_article_path(@article)

    assert_response :success
    assert_dom "h1", text: @article.title, count: 1
  end
end
