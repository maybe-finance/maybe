import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="tabs"
export default class extends Controller {
  static classes = ["active"];
  static targets = ["btn", "tab"];
  static values = { defaultTab: String };

  connect() {
    this.updateClasses(this.defaultTabValue);
    document.addEventListener("turbo:load", this.#turboHandler.bind(this));
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.#turboHandler.bind(this));
  }

  select(event) {
    this.updateClasses(event.target.dataset.id);
  }

  updateClasses(selectedId) {
    this.btnTargets.forEach((btn) => btn.classList.remove(this.activeClass));
    this.tabTargets.forEach((tab) => tab.classList.add("hidden"));

    this.btnTargets.forEach((btn) => {
      if (btn.dataset.id === selectedId) {
        btn.classList.add(this.activeClass);
      }
    });

    this.tabTargets.forEach((tab) => {
      if (tab.id === selectedId) {
        tab.classList.remove("hidden");
      }
    });
  }

  #turboHandler() {
    this.updateClasses(this.defaultTabValue);
  }
}
