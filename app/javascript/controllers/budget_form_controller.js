import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="budget-form"
export default class extends Controller {
  toggleAutoFill(e) {
    const expectedIncome = e.params.income;
    const budgetedAmount = e.params.amount;

    if (e.target.checked) {
      this.#fillField(expectedIncome.key, expectedIncome.value);
      this.#fillField(budgetedAmount.key, budgetedAmount.value);
    } else {
      this.#clearField(expectedIncome.key);
      this.#clearField(budgetedAmount.key);
    }
  }

  #fillField(id, value) {
    this.element.querySelector(`input[id="${id}"]`).value = value;
  }

  #clearField(id) {
    this.element.querySelector(`input[id="${id}"]`).value = "";
  }
}
