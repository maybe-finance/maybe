import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdown"
export default class extends Controller {
  static targets = ["menu"]

  toggleMenu(event) {
    event.stopPropagation(); // Prevent event from closing the menu immediately
    this.menuTarget.classList.toggle("hidden");
  }

  hideMenu() {
    this.menuTarget.classList.add("hidden");
  }

  connect() {
    document.addEventListener("click", () => this.hideMenu());
  }

  disconnect() {
    document.removeEventListener("click", () => this.hideMenu());
  }
}