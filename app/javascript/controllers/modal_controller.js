import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  connect() {
    this.element.showModal();
  }

  // Hide the dialog when the user clicks outside of it
  click_outside(e) {
    if (e.target === this.element) {
      this.element.close();
    }
  }
}
