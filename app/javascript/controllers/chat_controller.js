import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "form", "input"]

  connect() {
    this.scrollToBottom()
    this.setupAutoResize()
    this.setupMessageObserver()
  }

  scrollToBottom() {
    if (this.hasMessagesTarget) {
      const messagesContainer = this.messagesTarget.closest('#chat-container')
      if (messagesContainer) {
        messagesContainer.scrollTop = messagesContainer.scrollHeight
      }
    }
  }

  setupAutoResize() {
    if (this.hasInputTarget) {
      this.inputTarget.addEventListener('input', this.autoResize.bind(this))
      // Initialize height
      this.autoResize()
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

  disconnect() {
    // Clean up observer when controller is disconnected
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  autoResize() {
    const input = this.inputTarget
    // Reset height to calculate proper scrollHeight
    input.style.height = 'auto'
    // Set new height based on content
    input.style.height = (input.scrollHeight) + 'px'
    // Cap at 150px max height
    if (input.scrollHeight > 150) {
      input.style.height = '150px'
      input.style.overflowY = 'auto'
    } else {
      input.style.overflowY = 'hidden'
    }
  }

  submit(event) {
    // Let the form submit normally, but prepare for the response
    this.startLoadingState()
  }

  startLoadingState() {
    if (this.hasFormTarget) {
      this.formTarget.classList.add('opacity-50')
      this.formTarget.querySelector('button[type="submit"]').disabled = true
    }
  }

  endLoadingState() {
    if (this.hasFormTarget) {
      this.formTarget.classList.remove('opacity-50')
      this.formTarget.querySelector('button[type="submit"]').disabled = false
      this.formTarget.reset()
      this.autoResize()
    }
  }
} 