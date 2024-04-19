import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="money-field"
// when currency select change, update the input value with the correct placeholder and step 
export default class extends Controller {
  static targets = [ "amount", "currency" ]

  handleCurrencyChange() {
    const selectedCurrency = event.target.value
    this.updateAmount(selectedCurrency)
  }

  updateAmount(currency) {
    fetch(`/currencies/${currency}`)
      .then(response => response.json())
      .then(data => {
        this.amountTarget.placeholder = data.placeholder
        this.amountTarget.step = data.step
      })

  }
}