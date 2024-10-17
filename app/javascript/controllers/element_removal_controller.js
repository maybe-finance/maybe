import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="element-removal"
export default class extends Controller {
  remove() {
    this.element.remove();
  }
}
