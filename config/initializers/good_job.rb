Rails.application.configure do
  config.good_job.enable_cron = true
  config.good_job.cron = {
    maintenance: {
      cron: "0 22 * * *",
      class: "DailyExchangeRateJob"
    }
  }
end
