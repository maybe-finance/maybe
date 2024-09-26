module ImportsHelper
  def permitted_import_clean_path(import)
    if permitted_import_types.include?(import.type.underscore)
      "import/cleans/#{import.type.underscore}"
    else
      raise "Unknown import type: #{import.type}"
    end
  end

  def permitted_import_configuration_path(import)
    if permitted_import_types.include?(import.type.underscore)
      "import/configurations/#{import.type.underscore}"
    else
      raise "Unknown import type: #{import.type}"
    end
  end

  def permitted_import_step_path(import, step_idx)
    permitted_steps = %w[account_types accounts categories tags]

    step = import.mapping_steps[step_idx]

    if permitted_steps.include?(step)
      "import/confirms/steps/#{step}"
    else
      raise "Unknown import step type: #{step}"
    end
  end

  def permitted_import_row_form_path(import)
    if permitted_import_types.include?(import.type.underscore)
      "import/rows/#{import.type.underscore}/form"
    else
      raise "Unknown import type: #{import.type}"
    end
  end

  def cell_class(row, field)
    base = "text-sm focus:ring-gray-900 focus:border-gray-900 w-full max-w-full"

    row.valid? # populate errors

    border = row.errors.key?(field) ? "border-red-500" : "border-transparent"

    [ base, border ].join(" ")
  end

  private
    def permitted_import_types
      %w[transaction_import trade_import account_import mint_import]
    end
end
