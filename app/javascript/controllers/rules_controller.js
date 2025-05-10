import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="rules"
export default class extends Controller {
  static targets = [
    "conditionTemplate",
    "conditionGroupTemplate",
    "actionTemplate",
    "conditionsList",
    "actionsList",
    "effectiveDateInput",
  ];

  addConditionGroup() {
    this.#appendTemplate(
      this.conditionGroupTemplateTarget,
      this.conditionsListTarget,
    );
    this.updateConditionPrefixes();
  }

  addCondition() {
    this.#appendTemplate(
      this.conditionTemplateTarget,
      this.conditionsListTarget,
    );
    this.updateConditionPrefixes();
  }

  addAction() {
    this.#appendTemplate(this.actionTemplateTarget, this.actionsListTarget);
  }

  clearEffectiveDate() {
    this.effectiveDateInputTarget.value = "";
  }

  #appendTemplate(templateEl, listEl) {
    const html = templateEl.innerHTML.replaceAll(
      "IDX_PLACEHOLDER",
      this.#uniqueKey(),
    );

    listEl.insertAdjacentHTML("beforeend", html);
  }

  #uniqueKey() {
    return Date.now();
  }

  // Updates the prefix visibility of all conditions and condition groups
  // This is also called by the rule/conditions_controller when a subcondition is removed
  updateConditionPrefixes() {
    // Update conditions
    this.#updatePrefixesForList(this.conditionsListTarget);

    // Update subconditions for each condition group
    // We currently only support a single level of subconditions
    const groupSubLists = this.conditionsListTarget.querySelectorAll('[data-rule--conditions-target="subConditionsList"]');
    groupSubLists.forEach((subList) => {
      this.#updatePrefixesForList(subList);
    });
  }

  // Helper to update prefixes for a given list
  #updatePrefixesForList(listEl) {
    const items = Array.from(listEl.children);
    let conditionIdx = 0;
    items.forEach((item) => {
      const prefixEl = item.querySelector('[data-condition-prefix]');
      if (prefixEl) {
        if (conditionIdx === 0) {
          prefixEl.classList.add('hidden');
        } else {
          prefixEl.classList.remove('hidden');
        }
        conditionIdx++;
      }
    });
  }
}
