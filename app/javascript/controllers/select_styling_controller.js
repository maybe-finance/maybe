import { Controller } from "@hotwired/stimulus"

// Changes select field styling based on whether it has a value. Uses data-select-styling-empty-class-value and data-select-styling-value-class-value for CSS classes.
// Because SELECT elements don't have a value attribute, and placeholder CSS classes don't work for select elements
export default class extends Controller {
  static values = {
    emptyClass: { type: String, default: "text-secondary" },
    valueClass: { type: String, default: "text-primary" }
  }

  connect() {
    this.updateStyle()
    this.element.addEventListener("change", () => this.updateStyle())
  }

  updateStyle() {
    if (this.element.value) {
      this.element.classList.remove(this.emptyClassValue)
      this.element.classList.add(this.valueClassValue)
    } else {
      this.element.classList.remove(this.valueClassValue)
      this.element.classList.add(this.emptyClassValue)
    }
  }
}