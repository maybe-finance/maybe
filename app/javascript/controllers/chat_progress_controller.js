import { Controller } from "@hotwired/stimulus"

/**
 * A controller to handle AI progress updates in the chat interface
 */
export default class extends Controller {
  static targets = ["thinking"]

  connect() {
    console.log("ChatProgressController connected")
    this.setupProgressObserver()

    // Check if the thinking indicator is already visible
    if (this.hasThinkingTarget && !this.thinkingTarget.classList.contains('hidden')) {
      console.log("Thinking indicator is already visible on connect")
      this.scrollToBottom()
    }
  }

  setupProgressObserver() {
    if (this.hasThinkingTarget) {
      console.log("Setting up progress observer for thinking target")

      // Create a mutation observer to watch for changes to the thinking indicator
      this.observer = new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
          if (mutation.type === 'attributes' && mutation.attributeName === 'class') {
            this.handleThinkingVisibilityChange()
          } else if (mutation.type === 'childList') {
            this.handleThinkingContentChange()
          }
        })
      })

      // Start observing
      this.observer.observe(this.thinkingTarget, {
        attributes: true,
        childList: true,
        subtree: true
      })
    } else {
      console.warn("No thinking target found")

      // Try to find the thinking element by ID as a fallback
      const thinkingElement = document.getElementById('thinking')
      if (thinkingElement) {
        console.log("Found thinking element by ID")
        this.thinkingTarget = thinkingElement
        this.setupProgressObserver()
      }
    }
  }

  handleThinkingVisibilityChange() {
    const isHidden = this.thinkingTarget.classList.contains('hidden')
    console.log("Thinking visibility changed:", isHidden ? "hidden" : "visible")

    if (!isHidden) {
      // Scroll to the bottom when thinking indicator becomes visible
      this.scrollToBottom()

      // Force a redraw to ensure the indicator is visible
      void this.thinkingTarget.offsetHeight
    }
  }

  handleThinkingContentChange() {
    console.log("Thinking content changed")
    // Scroll to the bottom when thinking indicator content changes
    this.scrollToBottom()
  }

  scrollToBottom() {
    const messagesContainer = document.querySelector("[data-chat-scroll-target='messages']")
    if (messagesContainer) {
      setTimeout(() => {
        messagesContainer.scrollTop = messagesContainer.scrollHeight
      }, 100)
    }
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }
} 