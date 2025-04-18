import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="password-visibility"
export default class extends Controller {
  static targets = ["input", "showIcon", "hideIcon"];

  connect() {
    this.hideIconTarget.classList.add("hidden");
  }

  toggle() {
    const input = this.inputTarget;
    const type = input.type === "password" ? "text" : "password";
    input.type = type;

    this.showIconTarget.classList.toggle("hidden");
    this.hideIconTarget.classList.toggle("hidden");
  }
}
