import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="rule--actions"
export default class extends Controller {
  static values = { actionExecutors: Array };
  static targets = ["destroyField", "actionValue"];

  remove(e) {
    if (e.params.destroy) {
      this.destroyFieldTarget.value = true;
      this.element.classList.add("hidden");
    } else {
      this.element.remove();
    }
  }

  handleActionTypeChange(e) {
    const actionExecutor = this.actionExecutorsValue.find(
      (executor) => executor.key === e.target.value,
    );

    if (actionExecutor.type === "select") {
      this.#updateValueSelectFor(actionExecutor);
      this.#showAndEnableValueSelect();
    } else {
      this.#hideAndDisableValueSelect();
    }
  }

  get valueSelectEl() {
    return this.actionValueTarget.querySelector("select");
  }

  #showAndEnableValueSelect() {
    this.actionValueTarget.classList.remove("hidden");
    this.valueSelectEl.disabled = false;
  }

  #hideAndDisableValueSelect() {
    this.actionValueTarget.classList.add("hidden");
    this.valueSelectEl.disabled = true;
  }

  #updateValueSelectFor(actionExecutor) {
    // Clear existing options
    this.valueSelectEl.innerHTML = "";

    // Add new options
    for (const option of actionExecutor.options) {
      const optionEl = document.createElement("option");
      optionEl.value = option[1];
      optionEl.textContent = option[0];
      this.valueSelectEl.appendChild(optionEl);
    }
  }
}
