import { Controller } from "@hotwired/stimulus";

/**
 * A controller to toggle between chat list and chat content in the sidebar
 */
export default class extends Controller {
  static targets = ["button", "content", "defaultContent", "menuIcon", "backIcon", "header", "listHeader"];

  connect() {
    this.isShowingChatList = false;
  }

  toggle() {
    this.isShowingChatList = !this.isShowingChatList;

    if (this.isShowingChatList) {
      this.contentTarget.classList.remove("hidden");
      this.defaultContentTarget.classList.add("hidden");
      this.menuIconTarget.classList.add("hidden");
      this.backIconTarget.classList.remove("hidden");
      this.headerTarget.classList.add("hidden");
      this.listHeaderTarget.classList.remove("hidden");
    } else {
      this.contentTarget.classList.add("hidden");
      this.defaultContentTarget.classList.remove("hidden");
      this.menuIconTarget.classList.remove("hidden");
      this.backIconTarget.classList.add("hidden");
      this.headerTarget.classList.remove("hidden");
      this.listHeaderTarget.classList.add("hidden");
    }
  }
} 