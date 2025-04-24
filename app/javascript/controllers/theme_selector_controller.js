import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "radio"]

  selectTheme(event) {
    const container = event.currentTarget
    const radio = this.radioTargets.find(radio =>
      container.contains(radio)
    )

    if (radio && !radio.checked) {
      radio.checked = true

      const changeEvent = new Event('change', { bubbles: true })
      radio.dispatchEvent(changeEvent)
    }
  }
} 
