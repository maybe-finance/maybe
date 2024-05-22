module ImportTestHelper
  def valid_csv_str
    <<-ROWS
      date,name,category,tags,amount
      2024-01-01,Starbucks drink,Food & Drink,Tag1|Tag2,-8.55
      2024-01-01,Etsy,Shopping,Tag1,-80.98
      2024-01-02,Amazon stuff,Shopping,Tag2,-200
      2024-01-03,Paycheck,Income,,1000
    ROWS
  end

  def valid_csv_with_invalid_values
    <<-ROWS
      date,name,category,tags,amount
      invalid_date,Starbucks drink,Food,,invalid_amount
    ROWS
  end

  def valid_csv_with_missing_data
    <<-ROWS
      date,name,category,"optional id",amount
      2024-01-01,Drink,Food,1234,-200
      2024-01-02,,,,-100
    ROWS
  end

  def malformed_csv_str
    <<-ROWS
      name,age
      "John Doe,23
      "Jane Doe",25
    ROWS
  end
end
