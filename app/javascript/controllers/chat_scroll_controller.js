import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "messages"]

  connect() {
    this.scrollToBottom()
    this.setupMessageObserver()

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
    if (this.observer) {
      this.observer.disconnect()
    }

    if (this.resizeObserver) {
      this.resizeObserver.disconnect()
    }

    if (this.hasContainerTarget) {
      this.containerTarget.removeEventListener('scroll', this.handleScroll.bind(this))
    }
  }

  scrollToBottom() {
    if (this.hasContainerTarget) {
      const container = this.containerTarget
      container.scrollTop = container.scrollHeight
    }
  }

  handleScroll() {
    if (this.hasContainerTarget) {
      const container = this.containerTarget
      const scrollPosition = container.scrollTop + container.clientHeight
      const scrollThreshold = container.scrollHeight - 50

      // If user has scrolled up significantly, we'll track that
      if (scrollPosition < scrollThreshold) {
        this.userHasScrolled = true
      } else {
        this.userHasScrolled = false
      }
    }
  }

  setupResizeObserver() {
    if (this.hasContainerTarget) {
      this.resizeObserver = new ResizeObserver(() => {
        // Only auto-scroll to bottom if the user hasn't manually scrolled up
        if (!this.userHasScrolled) {
          this.scrollToBottom()
        }
      })

      this.resizeObserver.observe(this.containerTarget)
    }
  }

  setupMessageObserver() {
    // Create a mutation observer to watch for new messages
    this.observer = new MutationObserver((mutations) => {
      let shouldScroll = false

      mutations.forEach((mutation) => {
        if (mutation.addedNodes.length) {
          shouldScroll = true
        }
      })

      if (shouldScroll && !this.userHasScrolled) {
        // Use setTimeout to ensure DOM is fully updated before scrolling
        setTimeout(() => this.scrollToBottom(), 50)
      }
    })

    // Start observing the messages container and its children
    const targetNode = this.hasMessagesTarget ? this.messagesTarget : this.containerTarget
    this.observer.observe(targetNode, {
      childList: true,
      subtree: true
    })
  }
} 