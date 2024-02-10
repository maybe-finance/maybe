import { Controller } from "@hotwired/stimulus"
import { install, uninstall } from "@github/hotkey"

// Connects to data-controller="hotkey"
export default class extends Controller {
  connect() {
    install(this.element)
  }

  disconnect() {
    uninstall(this.element)
  }
}
