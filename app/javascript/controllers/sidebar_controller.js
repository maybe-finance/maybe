import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="sidebar"
export default class extends Controller {
  static values = {
    userId: String,
    config: Object,
  };

  static targets = ["leftPanel", "rightPanel", "content"];

  initialize() {
    this.leftPanelOpen = this.configValue.left_panel.is_open;
    this.rightPanelOpen = this.configValue.right_panel.is_open;
  }

  toggleLeftPanel() {
    this.leftPanelOpen = !this.leftPanelOpen;
    this.#updatePanelWidths();
    this.#persistPreference("show_sidebar", this.leftPanelOpen);
  }

  toggleRightPanel() {
    this.rightPanelOpen = !this.rightPanelOpen;
    this.#updatePanelWidths();
    this.#persistPreference("show_ai_sidebar", this.rightPanelOpen);
  }

  #updatePanelWidths() {
    this.contentTarget.style.maxWidth = `${this.#contentMaxWidth()}px`;
    this.leftPanelTarget.style.width = `${this.#leftPanelWidth()}px`;
    this.rightPanelTarget.style.width = `${this.#rightPanelWidth()}px`;
  }

  #leftPanelWidth() {
    if (this.leftPanelOpen) {
      return this.configValue.left_panel.min_width;
    }

    return 0;
  }

  #rightPanelWidth() {
    if (this.rightPanelOpen) {
      if (this.leftPanelOpen) {
        return this.configValue.right_panel.min_width;
      }

      return this.configValue.right_panel.max_width;
    }

    return 0;
  }

  #contentMaxWidth() {
    if (!this.leftPanelOpen && !this.rightPanelOpen) {
      return 1024;
    }

    if (this.leftPanelOpen && !this.rightPanelOpen) {
      return 896;
    }

    return 768;
  }

  #persistPreference(field, value) {
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
