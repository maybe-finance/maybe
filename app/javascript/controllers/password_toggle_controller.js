import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="password-toggle"
export default class extends Controller {
  static targets = ["input", "eyeIcon", "eyeOffIcon"];

  connect() {
    // Initial state is password hidden (eye icon visible, eye-off icon hidden)
    this.showEyeIcon();
  }

  toggle() {
    const passwordField = this.inputTarget;
    const isPasswordHidden = passwordField.type === "password";

    passwordField.type = isPasswordHidden ? "text" : "password";

    if (isPasswordHidden) {
      this.showEyeOffIcon();
    } else {
      this.showEyeIcon();
    }
  }

  showEyeIcon() {
    this.eyeIconTarget.classList.remove("hidden");
    this.eyeOffIconTarget.classList.add("hidden");
  }

  showEyeOffIcon() {
    this.eyeIconTarget.classList.add("hidden");
    this.eyeOffIconTarget.classList.remove("hidden");
  }
}