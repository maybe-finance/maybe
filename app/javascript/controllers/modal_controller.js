import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="modal"
export default class extends Controller {
  connect() {
    if (this.element.open) return;
    this.element.showModal();

    // Add event listener to disable submit button on form submission
    const submitButton = this.element.querySelector("#submit-button");
    if (submitButton) {
      submitButton.addEventListener(
        "click",
        this.disableSubmitButton.bind(this)
      );
    }
  }

  // Hide the dialog when the user clicks outside of it
  clickOutside(e) {
    if (e.target === this.element) {
      this.element.close();
    }
  }

  close() {
    this.element.close();
  }

  disableSubmitButton(event) {
    const submitButton = event.target;
    submitButton.disabled = true;
    submitButton.value = "Creating...";
    submitButton.form.submit();
  }
}
