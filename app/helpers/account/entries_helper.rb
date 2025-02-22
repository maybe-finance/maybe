module Account::EntriesHelper
  def entries_by_date(entries, totals: false)
    entries.group_by(&:date).map do |date, grouped_entries|
      content = capture do
        yield grouped_entries
      end

      next if content.blank?

      render partial: "account/entries/entry_group", locals: { date:, entries: grouped_entries, content:, totals: }
    end.compact.join.html_safe
  end

  def entry_name_detailed(entry)
    [
      entry.date,
      format_money(entry.amount_money),
      entry.account.name,
      entry.display_name
    ].join(" • ")
  end
end
