import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="transfer-match"
export default class extends Controller {
  static targets = ["newSelect", "existingSelect"];

  update(event) {
    if (event.target.value === "new") {
      this.newSelectTarget.classList.remove("hidden");
      this.existingSelectTarget.classList.add("hidden");
    } else {
      this.newSelectTarget.classList.add("hidden");
      this.existingSelectTarget.classList.remove("hidden");
    }
  }
}
