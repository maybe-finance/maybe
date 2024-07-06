// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";
import { Turbo } from "@hotwired/turbo-rails";

/**
 * This stream action can be used for updating any input field with a value, based on the content provided.
 * It also triggers an input event for any updated inputs.
 */
Turbo.StreamActions.update_input = function () {
  const inputEvent = new Event("input", { bubbles: true });
  for (const element of this.targetElements) {
    element.value = this.templateContent.textContent;
    element.dispatchEvent(inputEvent);
  }
};
