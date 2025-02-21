import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="tabs"
export default class extends Controller {
  static classes = ["active", "inactive"];
  static targets = ["btn", "tab"];
  static values = { defaultTab: String, localStorageKey: String };

  connect() {
    const selectedTab = this.hasLocalStorageKeyValue
      ? this.getStoredTab() || this.defaultTabValue
      : this.defaultTabValue;

    this.updateClasses(selectedTab);
    document.addEventListener("turbo:load", this.onTurboLoad);
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.onTurboLoad);
  }

  select(event) {
    const element = event.target.closest("[data-id]");
    if (element) {
      const selectedId = element.dataset.id;
      this.updateClasses(selectedId);
      if (this.hasLocalStorageKeyValue) {
        this.storeTab(selectedId);
      }
    }
  }

  onTurboLoad = () => {
    const selectedTab = this.hasLocalStorageKeyValue
      ? this.getStoredTab() || this.defaultTabValue
      : this.defaultTabValue;

    this.updateClasses(selectedTab);
  };

  getStoredTab() {
    const tabs = JSON.parse(localStorage.getItem("tabs") || "{}");
    return tabs[this.localStorageKeyValue];
  }

  storeTab(selectedId) {
    const tabs = JSON.parse(localStorage.getItem("tabs") || "{}");
    tabs[this.localStorageKeyValue] = selectedId;
    localStorage.setItem("tabs", JSON.stringify(tabs));
  }

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
