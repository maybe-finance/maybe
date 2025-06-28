import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    const chatController = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller~="chat"]'),
      "chat"
    );
    
    if (chatController) {
      chatController.focusInput();
    }
    
    this.element.remove();
  }
}