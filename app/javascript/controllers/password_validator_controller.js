import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="password-validator"
export default class extends Controller {
  static targets = ["input", "requirementType", "blockLine"];

  connect() {
    this.validate();
  }

  validate() {
    const password = this.inputTarget.value;
    let requirementsMet = 0;

    // Check each requirement and count how many are met
    const lengthValid = password.length >= 8;
    const caseValid = /[A-Z]/.test(password) && /[a-z]/.test(password);
    const numberValid = /\d/.test(password);
    const specialValid = /[!@#$%^&*(),.?":{}|<>]/.test(password);

    // Update individual requirement text
    this.validateRequirementText("length", lengthValid);
    this.validateRequirementText("case", caseValid);
    this.validateRequirementText("number", numberValid);
    this.validateRequirementText("special", specialValid);

    // Count total requirements met
    if (lengthValid) requirementsMet++;
    if (caseValid) requirementsMet++;
    if (numberValid) requirementsMet++;
    if (specialValid) requirementsMet++;

    // Update block lines sequentially
    this.updateBlockLines(requirementsMet);
  }

  validateRequirementText(type, isValid) {
    this.requirementTypeTargets.forEach((target) => {
      if (target.dataset.requirementType === type) {
        if (isValid) {
          target.classList.remove("text-secondary");
          target.classList.add("text-green-600");
        } else {
          target.classList.remove("text-green-600");
          target.classList.add("text-secondary");
        }
      }
    });
  }

  updateBlockLines(requirementsMet) {
    // Update block lines sequentially based on total requirements met
    this.blockLineTargets.forEach((line, index) => {
      if (index < requirementsMet) {
        line.classList.remove("bg-gray-200");
        line.classList.add("bg-green-600");
      } else {
        line.classList.remove("bg-green-600");
        line.classList.add("bg-gray-200");
      }
    });
  }
}
