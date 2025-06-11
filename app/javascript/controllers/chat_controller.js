import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["messages", "form", "input"];

  connect() {
    this.#configureAutoScroll();
    this.#setupFormSubmissionHandler();
  }

  disconnect() {
    if (this.messagesObserver) {
      this.messagesObserver.disconnect();
    }
  }

  autoResize() {
    const input = this.inputTarget;
    const lineHeight = 20; // text-sm line-height (14px * 1.429 ≈ 20px)
    const maxLines = 3; // 3 lines = 60px total

    input.style.height = "auto";
    input.style.height = `${Math.min(input.scrollHeight, lineHeight * maxLines)}px`;
    input.style.overflowY =
      input.scrollHeight > lineHeight * maxLines ? "auto" : "hidden";
  }

  submitSampleQuestion(e) {
    this.inputTarget.value = e.target.dataset.chatQuestionParam;

    setTimeout(() => {
      this.formTarget.requestSubmit();
      this.#refocusInput();
    }, 200);
  }

  // Newlines require shift+enter, otherwise submit the form (same functionality as ChatGPT and others)
  handleInputKeyDown(e) {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      this.formTarget.requestSubmit();
      // Maintain focus on input after submission
      this.#refocusInput();
    }
  }

  #configureAutoScroll() {
    this.messagesObserver = new MutationObserver((_mutations) => {
      if (this.hasMessagesTarget) {
        this.#scrollToBottom();
      }
    });

    // Listen to entire sidebar for changes, always try to scroll to the bottom
    this.messagesObserver.observe(this.element, {
      childList: true,
      subtree: true,
    });
  }

  #scrollToBottom = () => {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight;
  };

  #setupFormSubmissionHandler = () => {
    if (this.hasFormTarget) {
      this.formTarget.addEventListener("submit", () => {
        this.#refocusInput();
      });
    }
  };

  #refocusInput = () => {
    // Use setTimeout to ensure the form submission completes before refocusing
    setTimeout(() => {
      if (this.hasInputTarget) {
        this.inputTarget.focus();
      }
    }, 100);
  };
}
