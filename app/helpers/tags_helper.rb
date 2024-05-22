module TagsHelper
  def null_tag
    Tag.new \
      name: "Uncategorized",
      color: Tag::UNCATEGORIZED_COLOR
  end
end
