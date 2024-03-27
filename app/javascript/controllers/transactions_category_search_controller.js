import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="transactions-category-search"
export default class extends Controller {
  connect() {
    this.timeout = null;
  }

  search() {
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      this.submitForm();
    }, 800); // Debounce time in milliseconds
  }

  submitForm() {
    this.element.requestSubmit();
  }
}
