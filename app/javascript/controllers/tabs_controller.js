import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="tabs"
export default class extends Controller {
  static classes = ["active", "inactive", "navBtnActive", "navBtnInactive"];
  static targets = ["btn", "tab", "panel", "navBtn"];
  static values = {
    defaultTab: String,
    localStorageKey: String,
    urlParamKey: String,
  };

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

  show(e) {
    const selectedTabId = e.target.dataset.id;

    this.navBtnTargets.forEach((navBtn) => {
      if (navBtn.dataset.id === selectedTabId) {
        navBtn.classList.add(...this.navBtnActiveClasses);
        navBtn.classList.remove(...this.navBtnInactiveClasses);
      } else {
        navBtn.classList.add(...this.navBtnInactiveClasses);
        navBtn.classList.remove(...this.navBtnActiveClasses);
      }
    });

    this.panelTargets.forEach((panel) => {
      if (panel.dataset.id === selectedTabId) {
        panel.classList.remove("hidden");
      } else {
        panel.classList.add("hidden");
      }
    });

    // Update URL with the selected tab
    if (this.urlParamKeyValue) {
      const url = new URL(window.location.href);
      url.searchParams.set(this.urlParamKeyValue, selectedTabId);
      window.history.replaceState({}, "", url);
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
