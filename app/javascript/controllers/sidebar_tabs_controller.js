import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="sidebar-tabs"
export default class extends Controller {
  static targets = ["account"];

  select(event) {
    this.accountTargets.forEach((account) => {
      if (account.contains(event.target)) {
        account.classList.add("bg-container");
      } else {
        account.classList.remove("bg-container");
      }
    });
  }
}
