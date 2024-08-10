import {Controller} from "@hotwired/stimulus"

const TRADE_TYPES = {
  BUY: "buy",
  SELL: "sell",
  TRANSFER_IN: "transfer_in",
  TRANSFER_OUT: "transfer_out",
  INTEREST: "interest"
}

const FIELD_VISIBILITY = {
  [TRADE_TYPES.BUY]: {ticker: true, qty: true, price: true},
  [TRADE_TYPES.SELL]: {ticker: true, qty: true, price: true},
  [TRADE_TYPES.TRANSFER_IN]: {amount: true, transferAccount: true},
  [TRADE_TYPES.TRANSFER_OUT]: {amount: true, transferAccount: true},
  [TRADE_TYPES.INTEREST]: {amount: true}
}

// Connects to data-controller="trade-form"
export default class extends Controller {
  static targets = ["typeInput", "tickerInput", "amountInput", "transferAccountInput", "qtyInput", "priceInput"]

  connect() {
    this.handleTypeChange = this.handleTypeChange.bind(this)
    this.typeInputTarget.addEventListener("change", this.handleTypeChange)
    this.updateFields(this.typeInputTarget.value || TRADE_TYPES.BUY)
  }

  disconnect() {
    this.typeInputTarget.removeEventListener("change", this.handleTypeChange)
  }

  handleTypeChange(event) {
    this.updateFields(event.target.value)
  }

  updateFields(type) {
    const visibleFields = FIELD_VISIBILITY[type] || {}

    Object.entries(this.fieldTargets).forEach(([field, target]) => {
      const isVisible = visibleFields[field] || false

      // Update visibility
      target.hidden = !isVisible

      // Update required status based on visibility
      if (isVisible) {
        target.setAttribute('required', '')
      } else {
        target.removeAttribute('required')
      }
    })
  }

  get fieldTargets() {
    return {
      ticker: this.tickerInputTarget,
      amount: this.amountInputTarget,
      transferAccount: this.transferAccountInputTarget,
      qty: this.qtyInputTarget,
      price: this.priceInputTarget
    }
  }
}