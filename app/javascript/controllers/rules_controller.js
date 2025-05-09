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

  updateConditionPrefixes() {
    const items = this.conditionsListTarget.querySelectorAll('[data-condition-prefix]');
    items.forEach((el, idx) => {
      if (idx === 0) {
        el.classList.add('hidden');
      } else {
        el.classList.remove('hidden');
      }
    });
  }
}
