import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdown"
export default class extends Controller {
  static targets = ["menu"]
  static values = { closeOnClick: { type: Boolean, default: true } }

  toggleMenu = (e) => {
    e.stopPropagation(); // Prevent event from closing the menu immediately
    this.menuTarget.classList.contains("hidden") ? this.showMenu() : this.hideMenu();
  }

  showMenu = () => {
    document.addEventListener("click", this.onDocumentClick);
    this.menuTarget.classList.remove("hidden");
  }

  hideMenu = () => {
    document.removeEventListener("click", this.onDocumentClick);
    this.menuTarget.classList.add("hidden");
  }

  disconnect = () => {
    this.hideMenu();
  }

  onDocumentClick = (e) => {
    if (this.menuTarget.contains(e.target) && !this.closeOnClickValue ) {
      // user has clicked inside of the dropdown
      e.stopPropagation();
      return;
    }

    this.hideMenu();
  }
}
