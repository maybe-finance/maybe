import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "decoration"];
  static values = { selection: String };

  connect() {
    this.#renderOptions();
  }

  select({ target }) {
    this.selectionValue = target.dataset.value;
  }

  selectionValueChanged() {
    this.#options.forEach((option) => {
      if (option.dataset.value === this.selectionValue) {
        this.#check(option);
        this.inputTarget.value = this.selectionValue;
      } else {
        this.#uncheck(option);
      }
    });
  }

  #renderOptions() {
    this.#options.forEach((option) => {
      option.style.backgroundColor = option.dataset.value;
    });
  }

  #check(option) {
    option.setAttribute("aria-checked", "true");
    option.style.boxShadow = `0px 0px 0px 4px ${hexToRGBA(
      option.dataset.value,
      0.2,
    )}`;
    this.decorationTarget.style.backgroundColor = option.dataset.value;
  }

  #uncheck(option) {
    option.setAttribute("aria-checked", "false");
    option.style.boxShadow = "none";
  }

  get #options() {
    return Array.from(this.element.querySelectorAll("[role='radio']"));
  }
}

function hexToRGBA(hex, alpha = 1) {
  let hexCode = hex.replace(/^#/, "");
  let calculatedAlpha = alpha;

  if (hexCode.length === 8) {
    calculatedAlpha = Number.parseInt(hexCode.slice(6, 8), 16) / 255;
    hexCode = hexCode.slice(0, 6);
  }

  const r = Number.parseInt(hexCode.slice(0, 2), 16);
  const g = Number.parseInt(hexCode.slice(2, 4), 16);
  const b = Number.parseInt(hexCode.slice(4, 6), 16);

  return `rgba(${r}, ${g}, ${b}, ${calculatedAlpha})`;
}
