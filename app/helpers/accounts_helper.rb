module AccountsHelper
  def to_accountable_title(accountable)
    accountable.model_name.human
  end

  def accountable_text_class(accountable_type)
    class_mapping(accountable_type)[:text]
  end

  def accountable_bg_class(accountable_type)
    class_mapping(accountable_type)[:bg]
  end

  def accountable_bg_transparent_class(accountable_type)
    class_mapping(accountable_type)[:bg_transparent]
  end

  private

  def class_mapping(accountable_type)
    {
      "Account::Credit" => { text: "text-red-500", bg: "bg-red-500", bg_transparent: "bg-red-500/10" },
      "Account::Loan" => { text: "text-fuchsia-500", bg: "bg-fuchsia-500", bg_transparent: "bg-fuchsia-500/10" },
      "Account::OtherLiability" => { text: "text-gray-500", bg: "bg-gray-500", bg_transparent: "bg-gray-500/10" },
      "Account::Depository" => { text: "text-violet-500", bg: "bg-violet-500", bg_transparent: "bg-violet-500/10" },
      "Account::Investment" => { text: "text-blue-600", bg: "bg-blue-600", bg_transparent: "bg-blue-600/10" },
      "Account::OtherAsset" => { text: "text-green-500", bg: "bg-green-500", bg_transparent: "bg-green-500/10" },
      "Account::Property" => { text: "text-cyan-500", bg: "bg-cyan-500", bg_transparent: "bg-cyan-500/10" },
      "Account::Vehicle" => { text: "text-pink-500", bg: "bg-pink-500", bg_transparent: "bg-pink-500/10" }
    }.fetch(accountable_type, { text: "text-gray-500", bg: "bg-gray-500", bg_transparent: "bg-gray-500/10" })
  end
end
