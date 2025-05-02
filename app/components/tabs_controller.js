import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="tabs--components"
export default class extends Controller {
  static classes = ["navBtnActive", "navBtnInactive"];
  static targets = ["panel", "navBtn"];
  static values = { urlParamKey: String };

  show(e) {
    const btn = e.target.closest("button");
    const selectedTabId = btn.dataset.id;

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
}
