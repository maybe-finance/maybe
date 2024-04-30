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

  handleInput = () => {
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      this.element.requestSubmit();
    }, 500);
  };
}
