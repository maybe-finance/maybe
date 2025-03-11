import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="sidebar"
export default class extends Controller {
  static values = {
    userId: String,
    side: { type: String, default: "left" } // "left" or "right"
  };
  static targets = ["leftPanel", "rightPanel", "content"];

  toggle(event) {
    // Determine which sidebar to toggle based on the event or default to the side value
    const side = event.currentTarget.dataset.side || this.sideValue;

    // Get the appropriate panel based on the side
    const panel = side === "left" ? this.leftPanelTarget : this.rightPanelTarget;

    // Toggle the sidebar visibility
    if (side === "left") {
      panel.classList.toggle("w-0");
      panel.classList.toggle("opacity-0");
      panel.classList.toggle("w-80");
      panel.classList.toggle("opacity-100");
    } else {
      // For right panel, use the correct width class
      panel.classList.toggle("w-0");
      panel.classList.toggle("opacity-0");
      panel.classList.toggle("w-[375px]");
      panel.classList.toggle("opacity-100");
    }

    // Determine sidebar states
    const leftSidebarOpen = !this.leftPanelTarget.classList.contains("w-0");
    const rightSidebarOpen = !this.rightPanelTarget.classList.contains("w-0");

    // Adjust content width based on sidebar states
    this.adjustContentWidth(leftSidebarOpen, rightSidebarOpen);

    // Save user preference
    this.saveUserPreference(side, side === "left" ? leftSidebarOpen : rightSidebarOpen);
  }

  adjustContentWidth(leftSidebarOpen, rightSidebarOpen) {
    // Remove all possible width classes first
    this.contentTarget.classList.remove("max-w-3xl", "max-w-4xl", "max-w-5xl");

    // Apply the appropriate width class based on sidebar states
    if (leftSidebarOpen && rightSidebarOpen) {
      this.contentTarget.classList.add("max-w-3xl");
    } else if (leftSidebarOpen || rightSidebarOpen) {
      this.contentTarget.classList.add("max-w-4xl");
    } else {
      this.contentTarget.classList.add("max-w-5xl");
    }
  }

  saveUserPreference(side, isOpen) {
    const preferenceField = side === "left" ? "show_sidebar" : "show_ai_sidebar";

    fetch(`/users/${this.userIdValue}`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
        Accept: "application/json",
      },
      body: new URLSearchParams({
        [`user[${preferenceField}]`]: isOpen,
      }).toString(),
    });
  }
}
