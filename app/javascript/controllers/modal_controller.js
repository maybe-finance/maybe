import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  connect() {
    this.element.showModal();
  }

  click(e) {
    if (e.target === this.element) {
      this.element.close();
    }
  }
}
