import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [ "replacementCategoryField", "submitButton" ]
  static classes = [ "dangerousAction", "safeAction" ]
  static values = {
    submitTextWhenReplacing: String,
    submitTextWhenNotReplacing: String
  }

  updateSubmitButton() {
    if (this.replacementCategoryFieldTarget.value) {
      this.submitButtonTarget.value = this.submitTextWhenReplacingValue
      this.#markSafe()
    } else {
      this.submitButtonTarget.value = this.submitTextWhenNotReplacingValue
      this.#markDangerous()
    }
  }

  #markSafe() {
    this.submitButtonTarget.classList.remove(...this.dangerousActionClasses)
    this.submitButtonTarget.classList.add(...this.safeActionClasses)
  }

  #markDangerous() {
    this.submitButtonTarget.classList.remove(...this.safeActionClasses)
    this.submitButtonTarget.classList.add(...this.dangerousActionClasses)
  }
}
