import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  // By default, auto-submit is "opt-in" to avoid unexpected behavior.  Each `auto` target
  // will trigger a form submission when the configured event is triggered.
  static targets = ["auto"];
  static values = {
    triggerEvent: { type: String },
  };

  connect() {
    this.autoTargets.forEach((element) => {
      const event = this.#getEventForElement(element);
      element.addEventListener(event, this.handleInput);
    });
  }

  disconnect() {
    this.autoTargets.forEach((element) => {
      const event = this.#getEventForElement(element);
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

  #getEventForElement(element) {
    // Check for explicitly set event first
    if (element.dataset.autosubmitTriggerEvent) {
      return element.dataset.autosubmitTriggerEvent;
    }
    
    // Check form-level trigger event value
    if (this.triggerEventValue) {
      return this.triggerEventValue;
    }

    // Determine event based on input type
    const type = element.type || element.tagName.toLowerCase();

    switch (type) {
      case "text":
      case "email":
      case "password":
      case "search":
      case "tel":
      case "url":
      case "number":
      case "textarea":
        return "blur";
      case "select-one":
      case "select-multiple":
      case "checkbox":
      case "radio":
        return "change";
      case "date":
      case "datetime-local":
      case "month":
      case "time":
      case "week":
      case "color":
      case "range":
        return "change";
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
