// app/apps/investment_analytics/javascript/controllers/account_selector_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "accountSelect" ]

  selectAccount(event) {
    const accountId = event.target.value;
    const url = `/investment_analytics/dashboards?account_id=${accountId}`;
    Turbo.visit(url);
  }
}
