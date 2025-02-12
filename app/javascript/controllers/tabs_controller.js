import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="tabs"
export default class extends Controller {
  static classes = ["active", "inactive"];
  static targets = ["btn", "tab"];
  static values = { defaultTab: String };

  connect() {
    this.updateClasses(this.defaultTabValue);
    document.addEventListener("turbo:load", this.onTurboLoad);
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.onTurboLoad);
  }

  select(event) {
    const element = event.target.closest("[data-id]");
    if (element) {
      this.updateClasses(element.dataset.id);
    }
  }

  onTurboLoad = () => {
    this.updateClasses(this.defaultTabValue);
  };

  updateClasses = (selectedId) => {
    this.btnTargets.forEach((btn) => {
      btn.classList.remove(...this.activeClasses);
      btn.classList.remove(...this.inactiveClasses);
    });

    this.tabTargets.forEach((tab) => tab.classList.add("hidden"));

    this.btnTargets.forEach((btn) => {
      if (btn.dataset.id === selectedId) {
        btn.classList.add(...this.activeClasses);
      } else {
        btn.classList.add(...this.inactiveClasses);
      }
    });

    this.tabTargets.forEach((tab) => {
      if (tab.id === selectedId) {
        tab.classList.remove("hidden");
      }
    });
  };
}
