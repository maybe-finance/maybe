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
      const event = this.#getTriggerEvent(element);
      element.addEventListener(event, this.handleInput);
    });
  }

  disconnect() {
    this.autoTargets.forEach((element) => {
      const event = this.#getTriggerEvent(element);
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

  #getTriggerEvent(element) {
    // Check if element has explicit trigger event set
    if (element.dataset.autosubmitTriggerEvent) {
      return element.dataset.autosubmitTriggerEvent;
    }

    // Check if form has explicit trigger event set
    if (this.triggerEventValue !== "input") {
      return this.triggerEventValue;
    }

    // Otherwise, choose trigger event based on element type
    const type = element.type || element.tagName;

    switch (type.toLowerCase()) {
      case "text":
      case "email":
      case "password":
      case "search":
      case "tel":
      case "url":
      case "textarea":
        return "blur";
      case "number":
      case "date":
      case "datetime-local":
      case "month":
      case "time":
      case "week":
      case "color":
        return "change";
      case "checkbox":
      case "radio":
      case "select":
      case "select-one":
      case "select-multiple":
        return "change";
      case "range":
        return "input";
      default:
        return "blur";
    }
  }

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
