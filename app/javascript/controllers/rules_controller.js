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
  }

  addCondition() {
    this.#appendTemplate(
      this.conditionTemplateTarget,
      this.conditionsListTarget,
    );
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
}
