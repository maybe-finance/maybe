import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="country"
export default class extends Controller {
  static targets = ["country", "regionWrapper", "regionLabel"]

  connect() {
    this.updateRegionWrapperVisibility()
  }

  updateRegionWrapperVisibility() {
    if (this.countryTarget.value) {
      this.regionWrapperTarget.classList.remove("hidden")
      this.updateRegionLabel()
    } else {
      this.regionWrapperTarget.classList.add("hidden")
    }
  }

  updateRegionLabel() {
    this.regionLabelTarget.textContent =
      this.countryTarget.value === "US" ? "State" : "Region or City"
  }

  onCountryChange() {
    this.updateRegionWrapperVisibility()
  }
}