module ImportTestHelper
  def valid_csv_str
    <<-ROWS
      date,name,category,amount
      2024-01-01,Starbucks drink,Food,20
      2024-01-02,Amazon stuff,Shopping,200
    ROWS
  end

  def insufficient_columns_csv_str
    <<-ROWS
      date,name
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
