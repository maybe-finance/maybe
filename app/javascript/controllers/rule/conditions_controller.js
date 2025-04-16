import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="rule--conditions"
export default class extends Controller {
  static values = { conditionFilters: Array };
  static targets = [
    "destroyField",
    "filterValue",
    "operatorSelect",
    "subConditionTemplate",
    "subConditionsList",
  ];

  addSubCondition() {
    const html = this.subConditionTemplateTarget.innerHTML.replaceAll(
      "IDX_PLACEHOLDER",
      this.#uniqueKey(),
    );

    this.subConditionsListTarget.insertAdjacentHTML("beforeend", html);
  }

  remove(e) {
    if (e.params.destroy) {
      this.destroyFieldTarget.value = true;
      this.element.classList.add("hidden");
    } else {
      this.element.remove();
    }
  }

  handleConditionTypeChange(e) {
    const conditionFilter = this.conditionFiltersValue.find(
      (filter) => filter.key === e.target.value,
    );

    if (conditionFilter.type === "select") {
      this.#buildSelectFor(conditionFilter);
    } else {
      this.#buildTextInputFor(conditionFilter);
    }

    this.#updateOperatorsField(conditionFilter);
  }

  get valueInputEl() {
    const textInput = this.filterValueTarget.querySelector("input");
    const selectInput = this.filterValueTarget.querySelector("select");

    return textInput || selectInput;
  }

  #updateOperatorsField(conditionFilter) {
    this.operatorSelectTarget.innerHTML = "";

    for (const operator of conditionFilter.operators) {
      const optionEl = document.createElement("option");
      optionEl.value = operator[1];
      optionEl.textContent = operator[0];
      this.operatorSelectTarget.appendChild(optionEl);
    }
  }

  #buildSelectFor(conditionFilter) {
    const selectEl = this.#convertFormFieldTo("select", this.valueInputEl);

    for (const option of conditionFilter.options) {
      const optionEl = document.createElement("option");
      optionEl.value = option[1];
      optionEl.textContent = option[0];
      selectEl.appendChild(optionEl);
    }

    this.valueInputEl.replaceWith(selectEl);
  }

  #buildTextInputFor(conditionFilter) {
    const textInput = this.#convertFormFieldTo("input", this.valueInputEl);
    textInput.placeholder = "Enter a value";
    textInput.type = conditionFilter.type; // "text" || "number"
    if (conditionFilter.type === "number") {
      textInput.step = conditionFilter.number_step;
    }

    this.valueInputEl.replaceWith(textInput);
  }

  #convertFormFieldTo(type, el) {
    const priorClasses = el.classList;
    const priorId = el.id;
    const priorName = el.name;

    const newFormField = document.createElement(type);
    newFormField.classList.add(...priorClasses);
    newFormField.id = priorId;
    newFormField.name = priorName;

    return newFormField;
  }

  #uniqueKey() {
    return Math.random().toString(36).substring(2, 15);
  }
}
