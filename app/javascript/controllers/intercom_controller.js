import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="intercom"
export default class extends Controller {
  show() {
    Intercom("show");
  }
}
