import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="list-keyboard-navigation"
export default class extends Controller {
  focusPrevious() {
    this.focusLinkTargetInDirection(-1)
  }

  focusNext() {
    this.focusLinkTargetInDirection(1)
  }

  focusLinkTargetInDirection(direction) {
    const element = this.getLinkTargetInDirection(direction)
    element?.focus()
  }

  getLinkTargetInDirection(direction) {
    const indexOfLastFocus = this.indexOfLastFocus()
    return this.focusableLinks[indexOfLastFocus + direction]
  }

  indexOfLastFocus(targets = this.focusableLinks) {
    const indexOfActiveElement = targets.indexOf(document.activeElement)

    if (indexOfActiveElement !== -1) {
      return indexOfActiveElement
    } else {
      return targets.findIndex(target => target.getAttribute("tabindex") === "0")
    }
  }

  get focusableLinks() {
    return Array.from(this.element.querySelectorAll("a[href]"))
  }
}
