import { Controller } from "@hotwired/stimulus";
import { CurrenciesService } from "services/currencies_service";

// Connects to data-controller="money-field"
// when currency select change, update the input value with the correct placeholder and step
export default class extends Controller {
  static targets = ["amount", "currency", "symbol"];
  static values = { syncCurrency: Boolean };

  handleCurrencyChange(e) {
    const selectedCurrency = e.target.value;
    this.updateAmount(selectedCurrency);
    
    if (this.syncCurrencyValue) {
      this.syncOtherMoneyFields(selectedCurrency);
    }
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

  syncOtherMoneyFields(selectedCurrency) {
    // Find the form this money field belongs to
    const form = this.element.closest("form");
    if (!form) return;

    // Find all other money field controllers in the same form
    const allMoneyFields = form.querySelectorAll('[data-controller~="money-field"]');
    
    allMoneyFields.forEach(field => {
      // Skip the current field
      if (field === this.element) return;
      
      // Get the controller instance
      const controller = this.application.getControllerForElementAndIdentifier(field, "money-field");
      if (!controller) return;
      
      // Update the currency select if it exists
      if (controller.hasCurrencyTarget) {
        controller.currencyTarget.value = selectedCurrency;
        controller.updateAmount(selectedCurrency);
      }
    });
  }
}
