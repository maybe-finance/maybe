import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["search", "date"]

  connect() {
    this.timeout = null
  }

  search() {
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      this.submitForm();
    }, 300); // Debounce time in milliseconds
  }

  submitForm() {
    const formData = new FormData(this.searchTarget.form);
    const searchParams = new URLSearchParams(formData).toString();
    const newUrl = `${window.location.pathname}?${searchParams}`;
    
    history.pushState({}, '', newUrl);
    this.searchTarget.form.requestSubmit();
  }

  afterSubmit() {
    this.searchTarget.focus();
  }
}
