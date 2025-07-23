class BancoChileParser
  attr_reader :sheet
  def initialize(file)
    @file = file
  end

  def parse
    @sheet = Spreadsheet.open(@file).worksheet(0)
    parse_sheet
  rescue => e
    nil
  end

  private

  def parse_sheet
    return parse_cuenta_corriente if cuenta_corriente?

    return parse_tarjeta_credito_clp if tarjeta_de_credito_clp?

    parse_tarjeta_credito_usd if tarjeta_de_credito_usd?
  end

  def cuenta_corriente?
    @sheet[9,1] == "Cuenta:"
  end

  def tarjeta_de_credito_clp?
    @sheet[9,1] == "Tipo de Tarjeta:" && @sheet[17,8] == "Monto ($)"
  end

  def tarjeta_de_credito_usd?
    @sheet[9,1] == "Tipo de Tarjeta:" && @sheet[17,8] == "Monto (USD)"
  end

  def parse_cuenta_corriente
    csv_string = "date*,name,amount*,currency\n"
    reached_description = false
    @sheet.rows.each_with_index do |row, row_index|
      if row[2] == "Descripción"
        reached_description = true 
        next
      end
      next unless reached_description
      next if row[2].blank?
      # date
      d,m,y = row[1].split("/")
      csv_string << [m,d,y].join("/").concat(",")
      # name
      csv_string << row[2].concat(",")
      # amount
      csv_string << row[4].to_s.concat(",") if row[4].to_s.present?
      csv_string << "-#{row[5]}," if row[5].to_s.present?
      # currency
      csv_string << "CLP\n"
    end
    csv_string
  end

  def parse_tarjeta_credito_clp
    csv_string = "date*,name,amount*,currency\n"
    reached_description = false
    @sheet.rows.each_with_index do |row, row_index|
      if row[4] == "Descripción"
        reached_description = true 
        next
      end
      next unless reached_description
      next if row[2].blank?
      # date
      d,m,y = row[1].split("/")
      csv_string << [m,d,y].join("/").concat(",")
      # name
      csv_string << row[4].concat(",")
      # amount
      csv_string << row[10].to_s.concat(",") if row[10].to_s.present?
      csv_string << "-#{row[11]}," if row[11].to_s.present?
      # currency
      csv_string << "CLP\n"
    end
    csv_string
  end

  def parse_tarjeta_credito_usd
    csv_string = "date*,name,amount*,currency\n"
    reached_description = false
    @sheet.rows.each_with_index do |row, row_index|
      if row[4] == "Descripción"
        reached_description = true 
        next
      end
      next unless reached_description
      next if row[2].blank?
      # date
      d,m,y = row[1].split("/")
      csv_string << [m,d,y].join("/").concat(",")
      # name
      csv_string << row[4].concat(",")
      # amount
      csv_string << row[8].to_s.concat(",") if row[8].to_s.present?
      # currency
      csv_string << "USD\n"
    end
    csv_string
  end
end