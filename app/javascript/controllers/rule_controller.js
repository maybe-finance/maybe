import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="rule"
export default class extends Controller {
  static values = {
    registry: Object,
  };

  static targets = [
    "newConditionTemplate",
    "newActionTemplate",
    "conditionsList",
    "condition",
    "actionsList",
    "action",
    "destroyField",
    "operatorField",
    "valueField",
  ];

  initialize() {
    console.log(this.registryValue);
  }

  addCondition() {
    const html = this.newConditionTemplateTarget.innerHTML.replaceAll(
      "IDX_PLACEHOLDER",
      this.#uniqueKey(),
    );

    this.conditionsListTarget.insertAdjacentHTML("beforeend", html);
  }

  handleConditionTypeChange(e) {
    const definition = this.#getConditionFilterDefinition(e.target.value);
    const conditionEl = this.#getEventConditionEl(e.target);
    const valueFieldEl = this.#getFieldEl(this.valueFieldTargets, conditionEl);

    this.#updateOperatorsField(definition, conditionEl);

    if (definition.type === "select") {
      const selectEl = this.#buildSelectInput(definition, valueFieldEl);
      valueFieldEl.replaceWith(selectEl);
    } else {
      const inputEl = this.#buildTextInput(definition, valueFieldEl);
      valueFieldEl.replaceWith(inputEl);
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
    const definition = this.#getActionExecutorDefinition(e.target.value);
    const actionEl = this.#getEventActionEl(e.target);
    const valueFieldEl = this.#getFieldEl(this.valueFieldTargets, actionEl);

    if (definition.type === "select") {
      const selectEl = this.#buildSelectInput(definition, valueFieldEl);
      valueFieldEl.replaceWith(selectEl);
    } else {
      valueFieldEl.classList.add("hidden");
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

  #updateOperatorsField(definition, conditionEl) {
    const operatorFieldEl = this.#getFieldEl(
      this.operatorFieldTargets,
      conditionEl,
    );

    operatorFieldEl.innerHTML = definition.operators
      .map((operator) => {
        return `<option value="${operator}">${operator}</option>`;
      })
      .join("");
  }

  #buildTextInput(definition, fieldEl) {
    const inputEl = document.createElement("input");
    inputEl.setAttribute("data-rule-target", "valueField");
    inputEl.setAttribute("name", fieldEl.name);
    inputEl.setAttribute("id", fieldEl.id);
    inputEl.setAttribute("type", definition.type);

    return inputEl;
  }

  #buildSelectInput(definition, fieldEl) {
    const selectEl = document.createElement("select");
    selectEl.setAttribute("data-rule-target", "valueField");
    selectEl.setAttribute("name", fieldEl.name);
    selectEl.setAttribute("id", fieldEl.id);

    definition.options.forEach((option) => {
      const optionEl = document.createElement("option");
      optionEl.textContent = option[0];
      optionEl.value = option[1];
      selectEl.appendChild(optionEl);
    });

    return selectEl;
  }

  #destroyRuleItem(itemEl) {
    const destroyFieldEl = this.#getFieldEl(this.destroyFieldTargets, itemEl);

    itemEl.classList.add("hidden");
    destroyFieldEl.value = true;
  }

  #uniqueKey() {
    return `${Date.now()}_${Math.floor(Math.random() * 100000)}`;
  }

  #getConditionFilterDefinition(key) {
    return this.registryValue.filters.find((filter) => {
      return filter.key === key;
    });
  }

  #getActionExecutorDefinition(key) {
    return this.registryValue.executors.find((executor) => {
      return executor.key === key;
    });
  }

  #getEventConditionEl(childEl) {
    return this.conditionTargets.find((t) => t.contains(childEl));
  }

  #getEventActionEl(childEl) {
    return this.actionTargets.find((t) => t.contains(childEl));
  }

  #getFieldEl(targets, containerEl) {
    return targets.find((t) => containerEl.contains(t));
  }
}
