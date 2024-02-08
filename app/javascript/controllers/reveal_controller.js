import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="reveal"
export default class extends Controller {
  static targets = [ "content" ]

  toggle() {
    this.contentTargets.forEach(elem => elem.classList.toggle("hidden"));
  }
}
