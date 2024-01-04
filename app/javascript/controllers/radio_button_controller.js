import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="radio-button"
export default class extends Controller {
  static targets = ["label"];

  connect() {
    this.updateActiveState();
  }

  updateActiveState() {
    this.labelTargets.forEach((label) => {
      const input = label.querySelector("input[type='radio']");
      const checkmark = label.querySelector(".checkmark");
      const borderSpan = label.querySelector("span[aria-hidden='true']");

      if (input.checked) {
        label.classList.add("bg-white", "border", "shadow-sm");
        label.classList.remove("bg-gray-100", "border-transparent", "shadow-none");
        checkmark.classList.remove("invisible");
        borderSpan.classList.add("border-transparent");
        borderSpan.classList.remove("border-1");
      } else {
        label.classList.add("bg-gray-100", "border-transparent", "shadow-none");
        label.classList.remove("bg-white", "border", "shadow-sm");
        checkmark.classList.add("invisible");
        borderSpan.classList.add("border-1");
        borderSpan.classList.remove("border-transparent");
      }
    });
  }

  toggle(event) {
    event.preventDefault();
    const input = event.currentTarget.querySelector("input[type='radio']");
    input.checked = !input.checked;
    this.updateActiveState();
  }
}
