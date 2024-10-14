import { Controller } from "@hotwired/stimulus";
import { CurrenciesService } from "services/currencies_service";

// Connects to data-controller="money-field"
// when currency select change, update the input value with the correct placeholder and step
export default class extends Controller {
  static targets = ["amount", "currency", "symbol"];

  handleCurrencyChange(e) {
    const selectedCurrency = e.target.value;
    this.updateAmount(selectedCurrency);
  }

  updateAmount(currency) {
    new CurrenciesService().get(currency).then((currency) => {
      this.amountTarget.step = currency.step;

      if (Number.isFinite(this.amountTarget.value)) {
        this.amountTarget.value = Number.parseFloat(
          this.amountTarget.value,
        ).toFixed(currency.default_precision);
      }

      this.symbolTarget.innerText = currency.symbol;
    });
  }
}
