import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="selectable-link"
export default class extends Controller {
  connect() {
    this.element.addEventListener("change", this.handleChange.bind(this));
  }

  disconnect() {
    this.element.removeEventListener("change", this.handleChange.bind(this));
  }

  handleChange(event) {
    const paramName = this.element.name;
    const currentUrl = new URL(window.location.href);
    currentUrl.searchParams.set(paramName, event.target.value);

    Turbo.visit(currentUrl.toString());
  }
}
