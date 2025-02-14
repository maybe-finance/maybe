module AccountsHelper
  def summary_card(title:, &block)
    content = capture(&block)
    render "accounts/summary_card", title: title, content: content
  end 

  def accountable_groups_v2(accounts, classification: nil)
    filtered_accounts = if classification
      accounts.select { |a| a.classification == classification }
    else
      accounts
    end

    filtered_accounts.group_by(&:accountable_type).transform_keys { |k| Accountable.from_type(k) }
  end

  def accountable_groups(accounts, classification: nil)
    filtered_accounts = if classification
      accounts.select { |a| a.classification == classification }
    else
      accounts
    end

    groups = filtered_accounts.group_by(&:accountable_type)

    group_templates = groups.map do |accountable_type, accounts|
      render "accounts/accountable_group", accountable: accountable_type.constantize, accounts:
    end

    safe_join(group_templates)
  end
end
