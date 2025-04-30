import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="dialog"
export default class extends Controller {
  static targets = ["leftSidebar", "rightSidebar", "mobileSidebar"];
  static classes = ["leftSidebar", "rightSidebar"];

  openMobileSidebar() {
    this.mobileSidebarTarget.classList.remove("hidden");
  }

  closeMobileSidebar() {
    this.mobileSidebarTarget.classList.add("hidden");
  }

  toggleLeftSidebar() {
    this.#updateUserPreference(
      "show_sidebar",
      this.leftSidebarTarget.classList.contains("hidden"),
    );
    this.leftSidebarTarget.classList.toggle("hidden");
  }

  toggleRightSidebar() {
    this.#updateUserPreference(
      "show_ai_sidebar",
      this.rightSidebarTarget.classList.contains("hidden"),
    );
    this.rightSidebarTarget.classList.toggle("hidden");
  }

  #updateUserPreference(field, value) {
    fetch(`/users/${this.userIdValue}`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
        Accept: "application/json",
      },
      body: new URLSearchParams({
        [`user[${field}]`]: value,
      }).toString(),
    });
  }
}
