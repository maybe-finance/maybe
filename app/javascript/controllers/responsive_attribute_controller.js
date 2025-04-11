import { Controller } from "@hotwired/stimulus";
import { debounce } from "utils/debounce";

export default class extends Controller {
  static values = {
    mobile: String,
    desktop: String,
    breakpoint: { type: Number, default: 640 }, // sm breakpoint in Tailwind
    debounceTimeout: { type: Number, default: 250 },
    attribute: { type: String, default: "placeholder" }
  };

  connect() {
    this.debouncedUpdateValue = debounce(
      this.updateValue.bind(this),
      this.debounceTimeoutValue
    );

    window.addEventListener("resize", this.debouncedUpdateValue);

    this.updateValue();
  }

  disconnect() {
    window.removeEventListener("resize", this.debouncedUpdateValue);

    if (this.debouncedUpdateValue.cancel) {
      this.debouncedUpdateValue.cancel();
    }
  }

  updateValue() {
    const value = window.innerWidth < this.breakpointValue
      ? this.mobileValue
      : this.desktopValue;

    // Update the attribute
    this.element.setAttribute(this.attributeValue, value);
  }
}