import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="rule"
export default class extends Controller {
  static values = {
    conditionsRegistry: Array,
    actionsRegistry: Array,
  };

  static targets = [
    "newConditionTemplate",
    "newActionTemplate",
    "conditionsList",
    "condition",
    "actionsList",
    "action",
    "destroyInput",
  ];

  initialize() {
    console.log(this.conditionsRegistryValue);
    console.log(this.actionsRegistryValue);
  }

  addCondition() {
    const html = this.newConditionTemplateTarget.innerHTML.replaceAll(
      "IDX_PLACEHOLDER",
      this.#uniqueKey(),
    );

    this.conditionsListTarget.insertAdjacentHTML("beforeend", html);
  }

  handleConditionTypeChange(e) {
    const definition = this.conditionsRegistryValue.find((def) => {
      return def.condition_type === e.target.value;
    });

    const conditionEl = this.conditionTargets.find((t) => {
      return t.contains(e.target);
    });

    const operatorSelectEl = conditionEl.querySelector(
      "select[data-id='operator-select']",
    );

    operatorSelectEl.innerHTML = definition.operators
      .map((operator) => {
        return `<option value="${operator}">${operator}</option>`;
      })
      .join("");

    const valueInputEl = conditionEl.querySelector("[data-id='value-input']");

    if (definition.input_type === "select") {
      // Select input
      const selectEl = document.createElement("select");

      // Set data-id, name, id
      selectEl.setAttribute("data-id", "value-input");
      selectEl.setAttribute("name", valueInputEl.name);
      selectEl.setAttribute("id", valueInputEl.id);

      // Populate options
      definition.options.forEach((option) => {
        const optionEl = document.createElement("option");
        optionEl.value = option[1];
        optionEl.textContent = option[0];
        selectEl.appendChild(optionEl);
      });

      valueInputEl.replaceWith(selectEl);
    } else {
      // Text input
      const inputEl = document.createElement("input");
      inputEl.setAttribute("data-id", "value-input");
      inputEl.setAttribute("name", valueInputEl.name);
      inputEl.setAttribute("id", valueInputEl.id);
      inputEl.setAttribute("type", definition.input_type);

      valueInputEl.replaceWith(inputEl);
    }
  }

  addAction() {
    const html = this.newActionTemplateTarget.innerHTML.replaceAll(
      "IDX_PLACEHOLDER",
      this.#uniqueKey(),
    );

    this.actionsListTarget.insertAdjacentHTML("beforeend", html);
  }

  handleActionTypeChange(e) {
    const definition = this.actionsRegistryValue.find((def) => {
      return def.action_type === e.target.value;
    });

    const actionEl = this.actionTargets.find((t) => {
      return t.contains(e.target);
    });

    const valueInputEl = actionEl.querySelector("[data-id='value-input']");

    if (definition.input_type === "select") {
      const selectEl = document.createElement("select");
      selectEl.setAttribute("data-id", "value-input");
      selectEl.setAttribute("name", valueInputEl.name);
      selectEl.setAttribute("id", valueInputEl.id);

      definition.options.forEach((option) => {
        const optionEl = document.createElement("option");
        optionEl.value = option[1];
        optionEl.textContent = option[0];
        selectEl.appendChild(optionEl);
      });

      valueInputEl.replaceWith(selectEl);
    } else {
      valueInputEl.classList.add("hidden");
    }
  }

  removeCondition(e) {
    const conditionEl = this.conditionTargets.find((el) => {
      return el.contains(e.target);
    });

    if (e.params.destroy) {
      this.#destroyRuleItem(conditionEl);
    } else {
      conditionEl.remove();
    }
  }

  removeAction(e) {
    const actionEl = this.actionTargets.find((el) => {
      return el.contains(e.target);
    });

    if (e.params.destroy) {
      this.#destroyRuleItem(actionEl);
    } else {
      actionEl.remove();
    }
  }

  #destroyRuleItem(itemEl) {
    const destroyInputEl = this.destroyInputTargets.find((el) => {
      return itemEl.contains(el);
    });

    itemEl.classList.add("hidden");
    destroyInputEl.value = true;
  }

  #uniqueKey() {
    return `${Date.now()}_${Math.floor(Math.random() * 100000)}`;
  }
}
