import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [ "input", "decoration" ]
  static values = { selection: String }

  connect() {
    this.#renderOptions()
  }

  select({ target }) {
    this.selectionValue = target.dataset.value
  }

  selectionValueChanged() {
    this.#options.forEach(option => {
      if (option.dataset.value === this.selectionValue) {
        this.#check(option)
        this.inputTarget.value = this.selectionValue
      } else {
        this.#uncheck(option)
      }
    })
  }

  #renderOptions() {
    this.#options.forEach(option => option.style.backgroundColor = option.dataset.value)
  }

  #check(option) {
    option.setAttribute("aria-checked", "true")
    option.style.boxShadow = `0px 0px 0px 4px ${hexToRGBA(option.dataset.value, 0.2)}`
    this.decorationTarget.style.backgroundColor = option.dataset.value
  }

  #uncheck(option) {
    option.setAttribute("aria-checked", "false")
    option.style.boxShadow = "none"
  }

  get #options() {
    return Array.from(this.element.querySelectorAll("[role='radio']"))
  }
}

function hexToRGBA(hex, alpha = 1) {
  hex = hex.replace(/^#/, '');

  if (hex.length === 8) {
    alpha = parseInt(hex.slice(6, 8), 16) / 255;
    hex = hex.slice(0, 6);
  }

  let r = parseInt(hex.slice(0, 2), 16);
  let g = parseInt(hex.slice(2, 4), 16);
  let b = parseInt(hex.slice(4, 6), 16);

  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}
