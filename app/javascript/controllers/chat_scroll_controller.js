import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "messages"]

  connect() {
    console.log("ChatScrollController connected")
    this.scrollToBottom()
    this.setupMessageObserver()
    this.setupThinkingObserver()

    // Add event listener for manual scrolling (to detect if user has scrolled up)
    if (this.hasContainerTarget) {
      this.containerTarget.addEventListener('scroll', this.handleScroll.bind(this))
    }

    // Add resize observer to handle container resizing
    this.setupResizeObserver()

    // Set initial userHasScrolled state
    this.userHasScrolled = false
  }

  disconnect() {
    if (this.messageObserver) {
      this.messageObserver.disconnect()
    }
    if (this.thinkingObserver) {
      this.thinkingObserver.disconnect()
    }
    if (this.resizeObserver) {
      this.resizeObserver.disconnect()
    }

    if (this.hasContainerTarget) {
      this.containerTarget.removeEventListener('scroll', this.handleScroll.bind(this))
    }
  }

  scrollToBottom() {
    console.log("Scrolling to bottom")
    if (this.hasContainerTarget) {
      this.containerTarget.scrollTop = this.containerTarget.scrollHeight
    }
  }

  handleScroll() {
    if (this.hasContainerTarget) {
      const container = this.containerTarget
      const isScrolledToBottom = container.scrollHeight - container.scrollTop <= container.clientHeight + 50

      // Update userHasScrolled state based on scroll position
      this.userHasScrolled = !isScrolledToBottom

      console.log("User has scrolled:", this.userHasScrolled)
    }
  }

  setupResizeObserver() {
    if (this.hasContainerTarget) {
      this.resizeObserver = new ResizeObserver(() => {
        if (!this.userHasScrolled) {
          this.scrollToBottom()
        }
      })
      this.resizeObserver.observe(this.containerTarget)
    }
  }

  setupMessageObserver() {
    if (this.hasMessagesTarget) {
      console.log("Setting up message observer")
      // Create a mutation observer to watch for new messages
      this.messageObserver = new MutationObserver((mutations) => {
        let shouldScroll = false
        mutations.forEach((mutation) => {
          if (mutation.addedNodes.length) {
            shouldScroll = true
          }
        })

        if (shouldScroll && !this.userHasScrolled) {
          // Use setTimeout to ensure DOM is fully updated before scrolling
          setTimeout(() => this.scrollToBottom(), 0)
        }
      })

      // Start observing
      this.messageObserver.observe(this.messagesTarget, {
        childList: true,
        subtree: true
      })
    }
  }

  setupThinkingObserver() {
    // Watch for changes to the thinking indicator
    const thinkingElement = document.getElementById('thinking')
    if (thinkingElement) {
      console.log("Setting up thinking observer")
      this.thinkingObserver = new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
          if (mutation.type === 'attributes' && mutation.attributeName === 'class') {
            const isHidden = thinkingElement.classList.contains('hidden')
            console.log("Thinking visibility changed:", isHidden ? "hidden" : "visible")

            if (!isHidden && !this.userHasScrolled) {
              // Scroll to bottom when thinking indicator becomes visible
              setTimeout(() => this.scrollToBottom(), 0)
            }
          }
        })
      })

      // Start observing
      this.thinkingObserver.observe(thinkingElement, {
        attributes: true
      })
    }
  }
} 