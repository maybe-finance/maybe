import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="modal"
export default class extends Controller {
  connect() {
    this.element.addEventListener("turbo:submit-end", (event) => {
      if (event.detail.success) {
        this.element.close();
      }
    });
    if (this.element.open) return;
    else this.element.showModal();
  }

  // Hide the dialog when the user clicks outside of it
  clickOutside(e) {
    if (e.target === this.element) {
      this.element.close();
    }
  }

  close() {
    this.element.close();
  }
}
