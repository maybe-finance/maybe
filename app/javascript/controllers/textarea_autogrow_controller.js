import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.resize()
  }

  resize() {
    const textarea = this.element

    // Reset height to auto to get the correct scrollHeight
    textarea.style.height = "auto"

    // Set the height to match the content (with a max height)
    const newHeight = Math.min(textarea.scrollHeight, 150)
    textarea.style.height = `${newHeight}px`

    // Scroll to the bottom of the chat when the textarea grows
    const chatMessages = document.getElementById("chat-messages")
    if (chatMessages) {
      chatMessages.scrollTop = chatMessages.scrollHeight
    }
  }
} 