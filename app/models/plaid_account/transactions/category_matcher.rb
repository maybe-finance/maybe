# The purpose of this matcher is to auto-match Plaid categories to
# known internal user categories.  Since we allow users to define their own
# categories we cannot directly assign Plaid categories as this would overwrite
# user data and create a confusing experience.
#
# Automated category matching in the Maybe app has a hierarchy:
# 1. Naive string matching via CategoryAliasMatcher
# 2. Rules-based matching set by user
# 3. AI-powered matching (also enabled by user via rules)
#
# This class is simply a FAST and CHEAP way to match categories that are high confidence.
# Edge cases will be handled by user-defined rules.
class PlaidAccount::Transactions::CategoryMatcher
  include PlaidAccount::Transactions::CategoryTaxonomy

  def initialize(user_categories = [])
    @user_categories = user_categories
  end

  def match(plaid_detailed_category)
    plaid_category_details = get_plaid_category_details(plaid_detailed_category)
    return nil unless plaid_category_details

    # Try exact name matches first
    exact_match = normalized_user_categories.find do |category|
      category[:name] == plaid_category_details[:key].to_s
    end
    return user_categories.find { |c| c.id == exact_match[:id] } if exact_match

    # Try detailed aliases matches with fuzzy matching
    alias_match = normalized_user_categories.find do |category|
      name = category[:name]
      plaid_category_details[:aliases].any? do |a|
        alias_str = a.to_s

        # Try exact match
        next true if name == alias_str

        # Try plural forms
        next true if name.singularize == alias_str || name.pluralize == alias_str
        next true if alias_str.singularize == name || alias_str.pluralize == name

        # Try common forms
        normalized_name = name.gsub(/(and|&|\s+)/, "").strip
        normalized_alias = alias_str.gsub(/(and|&|\s+)/, "").strip
        normalized_name == normalized_alias
      end
    end
    return user_categories.find { |c| c.id == alias_match[:id] } if alias_match

    # Try parent aliases matches with fuzzy matching
    parent_match = normalized_user_categories.find do |category|
      name = category[:name]
      plaid_category_details[:parent_aliases].any? do |a|
        alias_str = a.to_s

        # Try exact match
        next true if name == alias_str

        # Try plural forms
        next true if name.singularize == alias_str || name.pluralize == alias_str
        next true if alias_str.singularize == name || alias_str.pluralize == name

        # Try common forms
        normalized_name = name.gsub(/(and|&|\s+)/, "").strip
        normalized_alias = alias_str.gsub(/(and|&|\s+)/, "").strip
        normalized_name == normalized_alias
      end
    end
    return user_categories.find { |c| c.id == parent_match[:id] } if parent_match

    nil
  end

  private
    attr_reader :user_categories

    def get_plaid_category_details(plaid_category_name)
      detailed_plaid_categories.find { |c| c[:key] == plaid_category_name.downcase.to_sym }
    end

    def detailed_plaid_categories
      CATEGORIES_MAP.flat_map do |parent_key, parent_data|
        parent_data[:detailed_categories].map do |child_key, child_data|
          {
            key: child_key,
            classification: child_data[:classification],
            aliases: child_data[:aliases],
            parent_key: parent_key,
            parent_aliases: parent_data[:aliases]
          }
        end
      end
    end

    def normalized_user_categories
      user_categories.map do |user_category|
        {
          id: user_category.id,
          classification: user_category.classification,
          name: normalize_user_category_name(user_category.name)
        }
      end
    end

    def normalize_user_category_name(name)
      name.to_s.downcase.gsub(/[^a-z0-9]/, " ").strip
    end
end
