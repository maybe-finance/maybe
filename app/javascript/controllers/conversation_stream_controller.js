import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="conversation-stream"
export default class extends Controller {
  connect() {
    console.log("ConversationStreamController connected");
    this.scrollToBottom()
    this.observeChatStream()
  }

  scrollToBottom() {
    console.log("scrollToBottom");
    console.log(this.element)
    console.log(this.element.scrollHeight)

    this.element.scrollTo({ top: this.element.scrollHeight, behavior: 'smooth' })
  }

  observeChatStream() {
    console.log("observeChatStream");
    const observer = new MutationObserver(() => {
      this.scrollToBottom()
    })

    observer.observe(this.element, {
      childList: true,
      subtree: true
    })
  }
}
