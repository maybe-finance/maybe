import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="conversation-form"
export default class extends Controller {
  static targets = ["content", "form"];
  submitting = false; // Add a flag to track submission state
  lastSubmittedContent = null; // Add a new property to store the last submitted content

  handleKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey && !this.submitting) {
      event.preventDefault();

      const contentValue = this.contentTarget.value.trim(); // Get the trimmed value of the content field

      // Check if content field has content and it's different from the last submitted content
      if (this.formTarget.checkValidity() && contentValue && contentValue !== this.lastSubmittedContent) {
        this.formTarget.requestSubmit();
        this.disableForm(); // Disable the form after submitting
        this.submitting = true; // Set the flag to true
        this.lastSubmittedContent = contentValue; // Update the lastSubmittedContent property
      }
    }
  }

  disableForm() {
    this.contentTarget.disabled = true;
  }

  enableForm() {
    this.contentTarget.disabled = false;
    this.submitting = false; // Reset the flag after enabling the form
  }

  clearContent(event) {
    if (event.detail.success) {
      this.contentTarget.value = "";
      this.enableForm(); // Enable the form after broadcast_append_to is done
    }
  }

  connect() {
    this.element.addEventListener("turbo:submit-end", this.clearContent.bind(this));
  }

  disconnect() {
    this.element.removeEventListener("turbo:submit-end", this.clearContent.bind(this));
  }
}