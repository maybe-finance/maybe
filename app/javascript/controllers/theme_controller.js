import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { userPreference: String };

  connect() {
    this.applyTheme();
    this.startSystemThemeListener();
  }

  disconnect() {
    this.stopSystemThemeListener();
  }

  // Called automatically by Stimulus when the userPreferenceValue changes (e.g., after form submit/page reload)
  userPreferenceValueChanged() {
    this.applyTheme();
  }

  // Called when a theme radio button is clicked
  updateTheme(event) {
    const selectedTheme = event.currentTarget.value;
    if (selectedTheme === "system") {
      this.setTheme(this.systemPrefersDark());
    } else if (selectedTheme === "dark") {
      this.setTheme(true);
    } else {
      this.setTheme(false);
    }
  }

  // Applies theme based on the userPreferenceValue (from server)
  applyTheme() {
    if (this.userPreferenceValue === "system") {
      this.setTheme(this.systemPrefersDark());
    } else if (this.userPreferenceValue === "dark") {
      this.setTheme(true);
    } else {
      this.setTheme(false);
    }
  }

  // Sets or removes the data-theme attribute
  setTheme(isDark) {
    if (isDark) {
      document.documentElement.setAttribute("data-theme", "dark");
    } else {
      document.documentElement.removeAttribute("data-theme");
    }
  }

  systemPrefersDark() {
    return window.matchMedia("(prefers-color-scheme: dark)").matches;
  }

  handleSystemThemeChange = (event) => {
    // Only apply system theme changes if the user preference is currently 'system'
    if (this.userPreferenceValue === "system") {
      this.setTheme(event.matches);
    }
  };

  toDark() {
    this.setTheme(true);
  }

  toLight() {
    this.setTheme(false);
  }

  toggle() {
    const currentTheme = document.documentElement.getAttribute("data-theme");
    if (currentTheme === "dark") {
      this.toLight();
    } else {
      this.toDark();
    }
  }

  startSystemThemeListener() {
    this.darkMediaQuery = window.matchMedia("(prefers-color-scheme: dark)");
    this.darkMediaQuery.addEventListener(
      "change",
      this.handleSystemThemeChange,
    );
  }

  stopSystemThemeListener() {
    if (this.darkMediaQuery) {
      this.darkMediaQuery.removeEventListener(
        "change",
        this.handleSystemThemeChange,
      );
    }
  }
}
