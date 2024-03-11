import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  connect() {
    if (this.element.open) return
    else this.element.showModal()
  }

  // Hide the dialog when the user clicks outside of it
  click_outside(e) {
    e.preventDefault()
    e.stopPropagation()
    if (e.target === this.element) {
      this.element.close();
    }
  }

  close() {
    this.element.close();
  }
}
