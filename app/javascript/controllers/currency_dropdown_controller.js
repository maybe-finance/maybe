import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdown"
export default class extends Controller {
  static targets = ["input", "label", "option"]

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
