import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "messages"]

  connect() {
    this.scrollToBottom()
    this.setupMessageObserver()
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  scrollToBottom() {
    if (this.hasContainerTarget) {
      this.containerTarget.scrollTop = this.containerTarget.scrollHeight
    }
  }

  setupMessageObserver() {
    if (this.hasMessagesTarget) {
      // Create a mutation observer to watch for new messages
      this.observer = new MutationObserver((mutations) => {
        let shouldScroll = false

        mutations.forEach((mutation) => {
          if (mutation.addedNodes.length) {
            shouldScroll = true
          }
        })

        if (shouldScroll) {
          // Use setTimeout to ensure DOM is fully updated before scrolling
          setTimeout(() => this.scrollToBottom(), 0)
        }
      })

      // Start observing
      this.observer.observe(this.messagesTarget, {
        childList: true,
        subtree: true
      })
    }
  }
} 