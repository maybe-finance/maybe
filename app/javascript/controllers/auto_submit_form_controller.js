import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  // By default, auto-submit is "opt-in" to avoid unexpected behavior.  Each `auto` target
  // will trigger a form submission when the input event is triggered.
  static targets = ["auto"];

  connect() {
    this.autoTargets.forEach((element) => {
      element.addEventListener("input", this.handleInput);
    });
  }

  disconnect() {
    this.autoTargets.forEach((element) => {
      element.removeEventListener("input", this.handleInput);
    });
  }

  handleInput = () => {
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      this.element.requestSubmit();
    }, 500);
  };
}
