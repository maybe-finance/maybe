import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="example-question"
export default class extends Controller {
  static values = { text: String }

  fillForm(event) {
    event.preventDefault()

    // Find the textarea in the form
    const textarea = document.querySelector("textarea[name='message[content]']")
    if (!textarea) return

    // Set the value and focus
    textarea.value = this.textValue
    textarea.focus()

    // Trigger input event to resize the textarea if using autogrow
    textarea.dispatchEvent(new Event('input'))
  }
} 