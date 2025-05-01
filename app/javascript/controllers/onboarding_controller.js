import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="onboarding"
export default class extends Controller {
  setLocale(event) {
    this.refreshWithParam("locale", event.target.value);
  }

  setDateFormat(event) {
    this.refreshWithParam("date_format", event.target.value);
  }

  setCurrency(event) {
    this.refreshWithParam("currency", event.target.value);
  }

  setTheme(event) {
    document.documentElement.setAttribute("data-theme", event.target.value);
  }

  refreshWithParam(key, value) {
    const url = new URL(window.location);
    url.searchParams.set(key, value);

    // Preserve existing params by getting the current search string
    // and appending our new param to it
    const currentParams = new URLSearchParams(window.location.search);
    currentParams.set(key, value);

    // Refresh the page with all params
    window.location.search = currentParams.toString();
  }
}
