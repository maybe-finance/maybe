import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="turbo-frame-timeout"
export default class extends Controller {
  static values = { timeout: { type: Number, default: 10000 } }

  connect() {
    this.timeoutId = setTimeout(() => {
      this.handleTimeout()
    }, this.timeoutValue)

    // Listen for successful frame loads to clear timeout
    this.element.addEventListener("turbo:frame-load", this.clearTimeout.bind(this))
  }

  disconnect() {
    this.clearTimeout()
  }

  clearTimeout() {
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
      this.timeoutId = null
    }
  }

  handleTimeout() {
    // Replace loading content with error state
    this.element.innerHTML = `
      <div class="flex items-center justify-end gap-1">
        <div class="w-8 h-4 flex items-center justify-center">
          <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-warning">
            <path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/>
            <path d="M12 9v4"/>
            <path d="m12 17 .01 0"/>
          </svg>
        </div>
        <p class="font-mono text-right text-xs text-warning">Timeout</p>
      </div>
    `
  }
} 