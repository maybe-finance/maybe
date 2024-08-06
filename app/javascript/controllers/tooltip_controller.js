import { Controller } from '@hotwired/stimulus'
import { createPopper } from "@popperjs/core";

export default class extends Controller {
  static targets = ["element", "tooltip"];
  static values = {
    placement: String,
    offset: Array
  };

  initialize() {
    this.placementValue = this.placementValue || "top"
    this.offsetValue = this.offsetValue || [0, 8]
  }

  connect() {
    this.popperInstance = createPopper(this.elementTarget, this.tooltipTarget, {
      placement: this.placementValue,
      modifiers: [
        {
          name: "offset",
          options: {
            offset: this.offsetValue,
          },
        },
      ],
    });
  }

  show(event) {
    this.hideAllElements();
    this.tooltipTarget.setAttribute("data-show", "");

    // We need to tell Popper to update the tooltip position
    // after we show the tooltip, otherwise it will be incorrect
    this.popperInstance.update();
  }

  hide(event) {
    this.tooltipTarget.removeAttribute("data-show");
  }

  hideAllElements() {
    document.querySelectorAll('#tooltip').forEach(element => element.removeAttribute("data-show"));
  }

  // Destroy the Popper instance
  disconnect() {
    if (this.popperInstance) {
      this.popperInstance.destroy();
    }
  }
}
