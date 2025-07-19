# Investment Analytics App for Maybe

This document outlines how to enable and use the optional "Investment Analytics" app within the Maybe project. This app provides Euclid-style portfolio analysis and uses the Financial Modeling Prep (FMP) API for market data.

## Features

*   **Portfolio Analysis:** Calculates total value, cost basis, gain/loss, and day-over-day change for your investment holdings.
*   **Dividend Forecasting:** Provides insights into potential annual dividend income and overall portfolio dividend yield.
*   **FMP Integration:** Fetches real-time and historical market data (quotes, historical prices, dividends) from the Financial Modeling Prep API.
*   **Background Sync:** Automatically synchronizes market data for your holdings.
*   **Hotwire UI:** Integrates seamlessly into Maybe's UI using Turbo Frames and ViewComponents.

## Installation and Setup

### 1. Enable the App

To enable the Investment Analytics app, set the `ENABLE_INVESTMENT_ANALYTICS_APP` environment variable to `true` in your `.env` file:

```dotenv
ENABLE_INVESTMENT_ANALYTICS_APP=true
```

### 2. Set FMP API Key

The app requires an API key from [Financial Modeling Prep (FMP)](https://financialmodelingprep.com/). Once you have your API key, add it to your `.env` file:

```dotenv
FMP_API_KEY=YOUR_FMP_API_KEY_HERE
```

**Note:** Without a valid FMP API key, the market data fetching and dividend analysis features will not function.

### 3. Rebuild and Restart Docker Compose

After modifying your `.env` file, you need to rebuild your Docker image and restart your Docker Compose services to pick up the new environment variables:

```bash
docker compose build
docker compose up -d
```

### 4. Run Initial Data Sync

To populate your database with initial market data, run the `InvestmentAnalytics::SyncJob`:

```bash
docker compose run --rm web bundle exec rails investment_analytics:sync
```

This command will fetch historical prices and dividend data for all active accounts with holdings. You can also run this job for a specific account by passing the `account_id`:

```bash
docker compose run --rm web bundle exec rails investment_analytics:sync[ACCOUNT_ID]
```

### 5. Access the Dashboard

Once the services are running and data has been synced, you can access the Investment Analytics dashboard by navigating to the following URL in your browser (assuming Maybe is running on port 3003):

```
http://localhost:3003/investment_analytics/dashboards
```

## Usage

*   **Dashboard:** The main dashboard provides an overview of your portfolio's market value, cost basis, and gain/loss.
*   **Account Selector:** Use the account selector to view analytics for different investment accounts.
*   **Dividend Forecast:** The dividend forecast section provides an estimated annual dividend income and yield for your holdings.

## Extending and Customizing

*   **Data Models:** The app uses Maybe's existing `Account`, `Holding`, `Price`, and `ExchangeRate` models. If you need to store additional data specific to investment analytics, consider extending these models or creating new ones within the `InvestmentAnalytics` namespace (`app/apps/investment_analytics/models`).
*   **FMP Provider:** The `InvestmentAnalytics::FmpProvider` can be extended or replaced if you wish to use a different market data source.
*   **Metrics:** The `MetricCalculator` and `DividendAnalyzer` can be modified to include more sophisticated metrics or forecasting models.
*   **UI Components:** New ViewComponents can be created within `app/apps/investment_analytics/app/components/investment_analytics/` to build out more complex UI elements.

## Running Tests

To run the tests for the Investment Analytics app:

```bash
bin/rspec spec/services/investment_analytics/
bin/rspec spec/jobs/investment_analytics/
bin/rspec spec/controllers/investment_analytics/
```

## License

This app is contributed to the Maybe project and is subject to the [AGPL license](https://github.com/maybe-finance/maybe/blob/main/LICENSE) of the main project.
