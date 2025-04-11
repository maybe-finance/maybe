import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="modal"
export default class extends Controller {
  static values = {
    reloadOnClose: { type: Boolean, default: false },
  };

  connect() {
    if (this.element.open) return;
    this.element.showModal();
  }

  // Hide the dialog when the user clicks outside of it
  clickOutside(e) {
    if (e.target === this.element) {
      this.close();
    }
  }

  close() {
    this.element.close();

    if (this.reloadOnCloseValue) {
      Turbo.visit(window.location.href);
    }
  }
}
