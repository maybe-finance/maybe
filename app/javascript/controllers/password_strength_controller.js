import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="password-strength"
export default class extends Controller {
  static targets = ["input", "minLength", "uppercase", "lowercase", "number", "special"];

  connect() {
    this.validatePassword();
  }

  validatePassword() {
    const password = this.inputTarget.value;

    const hasMinLength = password.length >= 8;
    const hasUppercase = /[A-Z]/.test(password);
    const hasLowercase = /[a-z]/.test(password);
    const hasNumber = /[0-9]/.test(password);
    const hasSpecial = /[!@#$%^&*(),.?":{}|<>]/.test(password);

    const hasUpperAndLower = hasUppercase && hasLowercase;

    this.updateIndicators(this.minLengthTargets, hasMinLength);
    this.updateIndicators(this.uppercaseTargets, hasUpperAndLower);
    this.updateIndicators(this.lowercaseTargets, hasLowercase);
    this.updateIndicators(this.numberTargets, hasNumber);
    this.updateIndicators(this.specialTargets, hasSpecial);

    const isValid = hasMinLength && hasUpperAndLower && hasNumber && hasSpecial;
    this.inputTarget.setCustomValidity(isValid ? "" : "Password doesn't meet requirements");
  }

  updateIndicators(elements, isValid) {
    elements.forEach(element => {
      if (element.classList.contains('rounded-full')) {
        this.updatePill(element, isValid);
      } else {
        this.updateText(element, isValid);
      }
    });
  }

  updatePill(element, isValid) {
    if (isValid) {
      element.classList.remove("bg-gray-200");
      element.classList.add("bg-green-500");
    } else {
      element.classList.remove("bg-green-500");
      element.classList.add("bg-gray-200");
    }
  }

  updateText(element, isValid) {
    if (isValid) {
      element.classList.remove("text-gray-500");
      element.classList.add("text-green-500");
    } else {
      element.classList.remove("text-green-500");
      element.classList.add("text-gray-500");
    }
  }
}