import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  // By default, auto-submit is "opt-in" to avoid unexpected behavior.  Each `auto` target
  // will trigger a form submission when the configured event is triggered.
  static targets = ["auto"];
  static values = {
    triggerEvent: { type: String, default: "input" },
  };

  connect() {
    this.autoTargets.forEach((element) => {
      const event =
        element.dataset.autosubmitTriggerEvent || this.triggerEventValue;
      element.addEventListener(event, this.handleInput);
    });
  }

  disconnect() {
    this.autoTargets.forEach((element) => {
      const event =
        element.dataset.autosubmitTriggerEvent || this.triggerEventValue;
      element.removeEventListener(event, this.handleInput);
    });
  }

  handleInput = (event) => {
    const target = event.target;

    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      this.element.requestSubmit();
    }, this.#debounceTimeout(target));
  };

  #debounceTimeout(element) {
    if (element.dataset.autosubmitDebounceTimeout) {
      return Number.parseInt(element.dataset.autosubmitDebounceTimeout);
    }

    const type = element.type || element.tagName;

    switch (type.toLowerCase()) {
      case "input":
      case "textarea":
        return 500;
      case "select-one":
      case "select-multiple":
        return 0;
      default:
        return 500;
    }
  }
}
