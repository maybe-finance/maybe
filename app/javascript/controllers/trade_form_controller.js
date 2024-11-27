import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="trade-form"
export default class extends Controller {
  // Reloads the page with a new type without closing the modal
  async changeType(event) {
    const url = new URL(event.params.url, window.location.origin);
    url.searchParams.set(event.params.key, event.target.value);
    Turbo.visit(url, { frame: "modal" });
  }
}
