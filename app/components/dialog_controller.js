import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="dialog"
export default class extends Controller {
  static values = {
    openOnLoad: { type: Boolean, default: true },
    reloadOnClose: { type: Boolean, default: false },
  };

  connect() {
    if (this.element.open) return;
    if (this.openOnLoadValue) {
      this.element.showModal();
    }
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
