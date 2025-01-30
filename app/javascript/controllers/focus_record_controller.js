import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="focus-record"
export default class extends Controller {
  static values = {
    id: String,
  };

  connect() {
    const element = document.getElementById(this.idValue);

    if (element) {
      element.scrollIntoView({ behavior: "smooth" });

      // Remove the focused_record_id parameter from URL
      const url = new URL(window.location);
      url.searchParams.delete("focused_record_id");
      window.history.replaceState({}, "", url);
    }
  }
}
