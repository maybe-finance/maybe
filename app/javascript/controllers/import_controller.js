import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="import"
export default class extends Controller {
  static values = {
    csv: { type: Array, default: [] },
    amountTypeColumnKey: { type: String, default: "" },
  };

  static targets = [
    "signedAmountFieldset",
    "customColumnFieldset",
    "amountTypeValue",
    "amountTypeStrategySelect",
  ];

  connect() {
    if (
      this.amountTypeStrategySelectTarget.value === "custom_column" &&
      this.amountTypeColumnKeyValue
    ) {
      this.#showAmountTypeValueTargets(this.amountTypeColumnKeyValue);
    }
  }

  handleAmountTypeStrategyChange(event) {
    const amountTypeStrategy = event.target.value;

    if (amountTypeStrategy === "custom_column") {
      this.#enableCustomColumnFieldset();

      if (this.amountTypeColumnKeyValue) {
        this.#showAmountTypeValueTargets(this.amountTypeColumnKeyValue);
      }
    }

    if (amountTypeStrategy === "signed_amount") {
      this.#enableSignedAmountFieldset();
    }
  }

  handleAmountTypeChange(event) {
    const amountTypeColumnKey = event.target.value;

    this.#showAmountTypeValueTargets(amountTypeColumnKey);
  }

  #showAmountTypeValueTargets(amountTypeColumnKey) {
    const selectableValues = this.#uniqueValuesForColumn(amountTypeColumnKey);

    this.amountTypeValueTarget.classList.remove("hidden");
    this.amountTypeValueTarget.classList.add("flex");

    const select = this.amountTypeValueTarget.querySelector("select");
    const currentValue = select.value;
    select.options.length = 0;
    const fragment = document.createDocumentFragment();

    // Only add the prompt if there's no current value
    if (!currentValue) {
      fragment.appendChild(new Option("Select value", ""));
    }

    selectableValues.forEach((value) => {
      const option = new Option(value, value);
      if (value === currentValue) {
        option.selected = true;
      }
      fragment.appendChild(option);
    });

    select.appendChild(fragment);
  }

  #uniqueValuesForColumn(column) {
    const colIdx = this.csvValue[0].indexOf(column);
    const values = this.csvValue.slice(1).map((row) => row[colIdx]);
    return [...new Set(values)];
  }

  #enableCustomColumnFieldset() {
    this.customColumnFieldsetTarget.classList.remove("hidden");
    this.signedAmountFieldsetTarget.classList.add("hidden");

    // Set required on custom column fields
    this.customColumnFieldsetTarget
      .querySelectorAll("select, input")
      .forEach((field) => {
        field.setAttribute("required", "");
      });

    // Remove required from signed amount fields
    this.signedAmountFieldsetTarget
      .querySelectorAll("select, input")
      .forEach((field) => {
        field.removeAttribute("required");
      });
  }

  #enableSignedAmountFieldset() {
    this.customColumnFieldsetTarget.classList.add("hidden");
    this.signedAmountFieldsetTarget.classList.remove("hidden");

    // Remove required from custom column fields
    this.customColumnFieldsetTarget
      .querySelectorAll("select, input")
      .forEach((field) => {
        field.removeAttribute("required");
      });

    // Set required on signed amount fields
    this.signedAmountFieldsetTarget
      .querySelectorAll("select, input")
      .forEach((field) => {
        field.setAttribute("required", "");
      });
  }
}
