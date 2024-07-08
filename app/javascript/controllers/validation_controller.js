import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="validation"
export default class extends Controller {
  static classes = ["invalid"];
  static targets = ["nonEmpty", "submit"];
  static values = { isValid: { type: Boolean, default: false } };

  isValidValueChanged() {
    if (!this.hasSubmitTarget) return;

    if (this.isValidValue) {
      this._makeSubmitValid();
    } else {
      this._makeSubmitInvalid();
    }
  }

  submitTargetConnected() {
    if (this.isValidValue) {
      this._makeSubmitValid();
    } else {
      this._makeSubmitInvalid();
    }
  }

  validate() {
    // Add the validation targets and their respective logic here.
    for (const target of this.nonEmptyTargets) {
      if (!target || !target.value || target.value === "") {
        this.isValidValue = false;
        return;
      }
    }

    this.isValidValue = true;
  }

  _makeSubmitValid() {
    this.element.classList.remove(this.invalidClass);
    this.submitTarget.disabled = false;
  }

  _makeSubmitInvalid() {
    this.element.classList.add(this.invalidClass);
    this.submitTarget.disabled = true;
  }
}
