import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "replacementField",
    "destructiveSubmitButton",
    "safeSubmitButton",
  ];

  static values = {
    submitTextWhenReplacing: String,
    submitTextWhenNotReplacing: String,
  };

  chooseSubmitButton() {
    if (this.replacementFieldTarget.value) {
      this.destructiveSubmitButtonTarget.hidden = true;
      this.safeSubmitButtonTarget.textContent =
        this.submitTextWhenReplacingValue;
      this.safeSubmitButtonTarget.hidden = false;
    } else {
      this.destructiveSubmitButtonTarget.textContent =
        this.submitTextWhenNotReplacingValue;
      this.destructiveSubmitButtonTarget.hidden = false;
      this.safeSubmitButtonTarget.hidden = true;
    }
  }
}
