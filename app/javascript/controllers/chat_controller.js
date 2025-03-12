import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="chat-scroll"
export default class extends Controller {
  static targets = ["form", "messages"];

  connect() {
    this.scrollToBottom();

    this.observer = new MutationObserver(() => {
      this.scrollToBottom();
      this.clearInput();
    });

    this.observer.observe(this.messagesTarget, {
      childList: true,
      subtree: true,
    });
  }

  disconnect() {
    this.observer.disconnect();
  }

  scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight;
  }

  clearInput() {
    this.formTarget.querySelector("textarea").value = "";
  }
}
