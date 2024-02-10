import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdown"
export default class extends Controller {
  static targets = ["menu", "input", "label", "option"]

  toggleMenu(event) {
    event.stopPropagation(); // Prevent event from closing the menu immediately
    this.repositionDropdown();
    this.menuTarget.classList.toggle("hidden");
  }

  hideMenu = () => {
    this.menuTarget.classList.add("hidden");
  }

  connect() {
    document.addEventListener("click", this.hideMenu);
  }

  disconnect() {
    document.removeEventListener("click", this.hideMenu);
  }

  repositionDropdown () {
    const button = this.menuTarget.previousElementSibling;
    const menu = this.menuTarget;

    // Calculate position
    const buttonRect = button.getBoundingClientRect();
    menu.style.top = `${buttonRect.bottom + window.scrollY}px`;
    menu.style.left = `${buttonRect.left + window.scrollX}px`;
  }

  selectOption (e) {
    const value = e.target.getAttribute('data-value');

    if (value) {
      // Remove active option background and tick
      this.optionTargets.forEach((element) => {
        element.classList.remove('bg-gray-100');
        element.children[0].classList.add('hidden');
      });

      // Set currency value and label
      this.inputTarget.value = value
      this.labelTarget.innerHTML = value

      // Reassign active option background and tick 
      e.currentTarget.classList.add('bg-gray-100')
      e.currentTarget.children[0].classList.remove('hidden');
    }
  }
}
