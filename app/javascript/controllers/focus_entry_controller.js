import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="focus-entry"
export default class extends Controller {
  static values = {
    id: String,
  };

  connect() {
    if (this.idValue) {
      // Wait for any Turbo navigation to complete
      document.addEventListener(
        "turbo:load",
        () => {
          const element = document.getElementById(this.idValue);
          if (element) {
            element.scrollIntoView({ behavior: "smooth" });

            // Remove the focused_entry_id parameter from URL
            const url = new URL(window.location);
            url.searchParams.delete("focused_entry_id");
            window.history.replaceState({}, "", url);
          }
        },
        { once: true },
      );
    }
  }
}
