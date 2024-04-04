import { Controller } from "@hotwired/stimulus";

/**
 * A "menu" can contain arbitrary content including non-clickable items, links, buttons, and forms.
 *
 * - If you need a form-enabled "select" element, use the "listbox" controller instead.
 */
export default class extends Controller {
  static targets = [
    "button",
    "content",
    "submenu",
    "submenuButton",
    "submenuContent",
  ];

  static values = {
    show: { type: Boolean, default: false },
    showSubmenu: { type: Boolean, default: false },
  };

  initialize() {
    this.show = this.showValue;
    this.showSubmenu = this.showSubmenuValue;
  }

  connect() {
    this.buttonTarget.addEventListener("click", this.toggle);
    this.element.addEventListener("keydown", this.handleKeydown);
    document.addEventListener("click", this.handleOutsideClick);
    document.addEventListener("turbo:load", this.handleTurboLoad);
  }

  disconnect() {
    this.element.removeEventListener("keydown", this.handleKeydown);
    this.buttonTarget.removeEventListener("click", this.toggle);
    document.removeEventListener("click", this.handleOutsideClick);
    document.removeEventListener("turbo:load", this.handleTurboLoad);
    this.close();
  }

  // If turbo reloads, we maintain the state of the menu
  handleTurboLoad = () => {
    if (!this.show) this.close();
  };

  handleOutsideClick = (event) => {
    if (this.show && !this.element.contains(event.target)) {
      this.close();
    }
  };

  handleKeydown = (event) => {
    switch (event.key) {
      case "Escape":
        this.close();
        this.buttonTarget.focus(); // Bring focus back to the button
        break;
    }
  };

  toggle = () => {
    this.show = !this.show;
    this.contentTarget.classList.toggle("hidden", !this.show);
    if (this.show) {
      this.focusFirstElement();
    }
  };

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
