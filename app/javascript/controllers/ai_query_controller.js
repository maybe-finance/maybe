import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="ai-query"
export default class extends Controller {
  static targets = ["input", "output", "form", "submit", "spinner"]

  connect() {
    this.resetOutput()
  }

  async query(event) {
    event.preventDefault()

    const query = this.inputTarget.value.trim()

    if (!query) return

    this.startLoading()
    this.resetOutput()

    try {
      const response = await fetch(this.formTarget.action, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        },
        body: JSON.stringify({ query })
      })

      const data = await response.json()

      if (data.success) {
        this.outputTarget.textContent = data.response
      } else {
        this.outputTarget.textContent = "Error: " + (data.response || "Something went wrong. Please try again.")
      }
    } catch (error) {
      console.error("AI Query error:", error)
      this.outputTarget.textContent = "Error: Could not process your request. Please try again."
    } finally {
      this.stopLoading()
    }
  }

  resetOutput() {
    this.outputTarget.textContent = "Ask any question about your finances..."
  }

  startLoading() {
    this.submitTarget.disabled = true
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.remove("hidden")
    }
  }

  stopLoading() {
    this.submitTarget.disabled = false
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.add("hidden")
    }
  }
} 