import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submit"]

  connect() {
    console.log("MessageFormController connected")
    this.thinkingElement = document.getElementById("thinking")
    console.log("Thinking element:", this.thinkingElement)
  }

  reset() {
    console.log("MessageFormController reset called")
    this.element.reset()
    this.element.querySelector("textarea").style.height = "auto"

    // We don't hide the thinking indicator here anymore
    // It will be hidden by the ProcessAiResponseJob when the AI response is ready
  }

  checkSubmit(event) {
    console.log("MessageFormController checkSubmit called", event.key)
    // Submit the form when Enter is pressed without Shift
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.submitForm()
    }
  }

  submitForm() {
    console.log("MessageFormController submitForm called")

    // Get the form action to determine if we're creating a new chat or adding to existing
    const isNewChat = this.element.action.includes('/chats') && !this.element.action.includes('/messages');
    console.log("Is new chat:", isNewChat);

    // Show the thinking indicator
    if (this.thinkingElement) {
      console.log("Showing thinking indicator")
      this.thinkingElement.classList.remove("hidden")

      // Force a redraw to ensure the indicator is visible
      void this.thinkingElement.offsetHeight;

      // Scroll to the bottom of the chat to show the thinking indicator
      const chatMessages = document.querySelector("[data-chat-scroll-target='messages']")
      if (chatMessages) {
        setTimeout(() => {
          chatMessages.scrollTop = chatMessages.scrollHeight
        }, 100)
      }
    } else {
      console.warn("Thinking element not found")
    }

    console.log("Submit target:", this.submitTarget)
    this.element.requestSubmit(this.submitTarget)
  }
} 