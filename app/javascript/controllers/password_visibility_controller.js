import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="password-visibility"
export default class extends Controller {
  static targets = ["input", "icon"]

  toggle() {
    const input = this.inputTarget
    const type = input.type === "password" ? "text" : "password"
    input.type = type
    
    // Toggle icon
    if (type === "password") {
      this.iconTarget.dataset.icon = "eye"
    } else {
      this.iconTarget.dataset.icon = "eye-off"
    }
  }
} 