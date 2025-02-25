import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="sidebar"
export default class extends Controller {
  static values = { userId: String };
  static targets = ["panel", "content"];

  toggle() {
    this.panelTarget.classList.toggle("w-0");
    this.panelTarget.classList.toggle("opacity-0");
    this.panelTarget.classList.toggle("w-80");
    this.panelTarget.classList.toggle("opacity-100");
    this.contentTarget.classList.toggle("max-w-4xl");
    this.contentTarget.classList.toggle("max-w-5xl");

    fetch(`/users/${this.userIdValue}`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
        Accept: "application/json",
      },
      body: new URLSearchParams({
        "user[show_sidebar]": !this.panelTarget.classList.contains("w-0"),
      }).toString(),
    });
  }
}
