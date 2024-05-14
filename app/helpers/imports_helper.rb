module ImportsHelper
  def table_corner_class(row_idx, col_idx, rows, cols)
    return "rounded-tl-xl" if row_idx == 0 && col_idx == 0
    return "rounded-tr-xl" if row_idx == 0 && col_idx == cols.size - 1
    return "rounded-bl-xl" if row_idx == rows.size - 1 && col_idx == 0
    return "rounded-br-xl" if row_idx == rows.size - 1 && col_idx == cols.size - 1
    ""
  end

  def nav_steps(import = Import.new)
    [
      { name: "Select", complete: import.persisted?, path: import.persisted? ? edit_import_path(import) : new_import_path },
      { name: "Import", complete: import.loaded?, path: import.persisted? ? load_import_path(import) : nil },
      { name: "Setup", complete: import.configured?, path: import.persisted? ? configure_import_path(import) : nil },
      { name: "Clean", complete: import.cleaned?, path: import.persisted? ? clean_import_path(import) : nil },
      { name: "Confirm", complete: import.complete?, path: import.persisted? ? confirm_import_path(import) : nil }
    ]
  end
end
