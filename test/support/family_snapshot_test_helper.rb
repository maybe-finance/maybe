module FamilySnapshotTestHelper
  # See: https://docs.google.com/spreadsheets/d/18LN5N-VLq4b49Mq1fNwF7_eBiHSQB46qQduRtdAEN98/edit?usp=sharing
  def get_expected_balances_for(key)
    expected_results_file.map do |row|
      {
        date: (Date.current - row["date_offset"].to_i.days).to_date,
        balance: row[key.to_s].to_d
      }
    end
  end

  def get_today_snapshot_value_for(metric)
    expected_results_file[-1][metric.to_s].to_d
  end

  private

    def expected_results_file
      CSV.read("test/fixtures/files/expected_family_snapshots.csv", headers: true)
    end
end
