import { Controller } from "@hotwired/stimulus"

// Controls the password validation requirements UI
export default class extends Controller {
  static targets = [
    "lengthIconX", "lengthIconCheck", "caseIconX", "caseIconCheck",
    "numberIconX", "numberIconCheck", "specialIconX", "specialIconCheck",
    "lengthBar", "caseBar", "numberBar", "specialBar"
  ]

  connect() {
    // Initialize if there's already a password value
    if (this.passwordField && this.passwordField.value) {
      this.validateCriteria()
    }
  }

  validateCriteria() {
    const password = this.passwordField.value

    // Validate minimum length (8 characters)
    const hasLength = password.length >= 8
    this.updateCriterionIcons(this.lengthIconXTarget, this.lengthIconCheckTarget, hasLength)
    this.updateBar(this.lengthBarTarget, hasLength)

    // Validate upper and lowercase letters
    const hasCase = /[a-z]/.test(password) && /[A-Z]/.test(password)
    this.updateCriterionIcons(this.caseIconXTarget, this.caseIconCheckTarget, hasCase)
    this.updateBar(this.caseBarTarget, hasCase)

    // Validate numbers
    const hasNumber = /[0-9]/.test(password)
    this.updateCriterionIcons(this.numberIconXTarget, this.numberIconCheckTarget, hasNumber)
    this.updateBar(this.numberBarTarget, hasNumber)

    // Validate special characters
    const hasSpecial = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password)
    this.updateCriterionIcons(this.specialIconXTarget, this.specialIconCheckTarget, hasSpecial)
    this.updateBar(this.specialBarTarget, hasSpecial)
  }

  updateCriterionIcons(xIcon, checkIcon, isValid) {
    if (isValid) {
      xIcon.classList.add("hidden")
      checkIcon.classList.remove("hidden")
    } else {
      xIcon.classList.remove("hidden")
      checkIcon.classList.add("hidden")
    }
  }

  updateBar(barElement, isValid) {
    if (isValid) {
      barElement.classList.remove("bg-gray-200")
      barElement.classList.add("bg-green-500")
    } else {
      barElement.classList.remove("bg-green-500")
      barElement.classList.add("bg-gray-200")
    }
  }

  get passwordField() {
    return this.element.querySelector('input[name="user[password]"]')
  }
}