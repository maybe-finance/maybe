module ImportsHelper
  def cell_class(row, field)
    base = "focus:ring-gray-900 focus:border-gray-900 max-w-full"

    row.valid? # populate errors

    border = row.errors.key?(field) ? "border-red-500" : "border-transparent"

    [ base, border ].join(" ")
  end
end
