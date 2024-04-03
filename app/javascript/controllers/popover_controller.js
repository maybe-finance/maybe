import { Controller } from "@hotwired/stimulus";

/**
 * A "popover" is a "general purpose menu" that can contain arbitrary content including non-clickable items, links, buttons, and forms.
 *
 * - If you need a form-enabled "select" element, use the "listbox" controller instead.
 */
export default class extends Controller {
  static targets = ["button", "content"];

  connect() {
    this.show = false;
    this.contentTarget.classList.add("hidden"); // Initially hide the popover
    this.element.addEventListener("keydown", this.handleKeydown);
    document.addEventListener("click", this.handleOutsideClick);
  }

  disconnect() {
    document.removeEventListener("click", this.handleOutsideClick);
  }

  handleOutsideClick = (event) => {
    if (this.show && !this.element.contains(event.target)) {
      this.close();
    }
  };

  handleKeydown = (event) => {
    switch (event.key) {
      case " ":
      case "Escape":
        this.close();
        this.buttonTarget.focus(); // Bring focus back to the button
        break;
    }
  };

  toggle() {
    this.show = !this.show;
    this.contentTarget.classList.toggle("hidden", !this.show);
    if (this.show) {
      this.focusFirstElement();
    }
  }

  close() {
    this.show = false;
    this.contentTarget.classList.add("hidden");
  }

  focusFirstElement() {
    const focusableElements =
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])';
    const firstFocusableElement =
      this.contentTarget.querySelectorAll(focusableElements)[0];
    if (firstFocusableElement) {
      firstFocusableElement.focus();
    }
  }
}
