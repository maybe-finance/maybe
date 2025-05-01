import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="dialog"
export default class extends Controller {
  static targets = ["content"]

  static values = {
    autoOpen: { type: Boolean, default: false },
    reloadOnClose: { type: Boolean, default: false },
  };

  connect() {
    if (this.element.open) return;
    if (this.autoOpenValue) {
      this.element.showModal();
    }
  }
  
  // If the user clicks anywhere outside of the visible content, close the dialog
  clickOutside(e) {
    if (!this.contentTarget.contains(e.target)) {
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
