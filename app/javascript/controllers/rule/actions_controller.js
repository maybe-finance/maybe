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
      this.#convertToSelect(actionExecutor);
      this.#showActionValue();
    } else if (actionExecutor.type === "text") {
      this.#convertToTextInput();
      this.#showActionValue();
    } else {
      this.#hideActionValue();
    }
  }

  get valueSelectEl() {
    return this.actionValueTarget.querySelector("select");
  }

  get valueInputEl() {
    return this.actionValueTarget.querySelector("input");
  }

  #showActionValue() {
    this.actionValueTarget.classList.remove("hidden");
  }

  #hideActionValue() {
    this.actionValueTarget.classList.add("hidden");
  }


  #convertToTextInput() {
    // If we already have a text input, do nothing
    if (this.valueInputEl && this.valueInputEl.type === "text") {
      return;
    }

    // Convert select to text input
    const valueField = this.valueSelectEl || this.valueInputEl;

    if (valueField) {
      const textInput = document.createElement("input");
      textInput.type = "text";
      textInput.name = valueField.name;
      textInput.id = valueField.id;
      textInput.placeholder = "Enter a value";
      textInput.className = "form-field__input";

      valueField.replaceWith(textInput);
    }
  }

  // Converts a field to a select with new options based on the action executor
  // This includes a current select with different options
  #convertToSelect(actionExecutor) {
    const valueField = this.valueInputEl || this.valueSelectEl;

    if (!valueField) {
      return;
    }

    const selectInput = document.createElement("select");
    selectInput.name = valueField.name;
    selectInput.id = valueField.id;
    selectInput.className = "form-field__input";

    // Add options
    for (const option of actionExecutor.options) {
      const optionEl = document.createElement("option");
      optionEl.value = option[1];
      optionEl.textContent = option[0];
      selectInput.appendChild(optionEl);
    }

    valueField.replaceWith(selectInput);
  }
}
