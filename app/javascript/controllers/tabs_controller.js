import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="tabs"
export default class extends Controller {
  static classes = ["active"];
  static targets = ["btn", "tab"];
  static values = { defaultTab: String };

  connect() {
    const defaultTab = this.defaultTabValue;
    this.tabTargets.forEach((tab) => {
      if (tab.id === defaultTab) {
        tab.hidden = false;
        this.btnTargets
          .find((btn) => btn.dataset.id === defaultTab)
          .classList.add(...this.activeClasses);
      } else {
        tab.hidden = true;
      }
    });
  }

  select(event) {
    const selectedTabId = event.currentTarget.dataset.id;
    this.tabTargets.forEach((tab) => (tab.hidden = tab.id !== selectedTabId));
    this.btnTargets.forEach((btn) =>
      btn.classList.toggle(
        ...this.activeClasses,
        btn.dataset.id === selectedTabId
      )
    );
  }
}
