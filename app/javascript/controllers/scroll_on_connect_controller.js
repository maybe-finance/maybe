import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    selector: { type: String, default: "[aria-current=\"page\"]" },
    delay: { type: Number, default: 500 }
  }

  connect() {
    setTimeout(() => {
      this.scrollToActiveItem()
    }, this.delayValue)
  }

  scrollToActiveItem() {
    const activeItem = this.element?.querySelector(this.selectorValue)


    if (!activeItem) return

    const scrollContainer = this.element
    const containerRect = scrollContainer.getBoundingClientRect()
    const activeItemRect = activeItem.getBoundingClientRect()

    const scrollPositionX = (activeItemRect.left + scrollContainer.scrollLeft) -
                          (containerRect.width / 2) +
                          (activeItemRect.width / 2)

    const scrollPositionY = (activeItemRect.top + scrollContainer.scrollTop) -
                          (containerRect.height / 2) +
                          (activeItemRect.height / 2)


    // Smooth scroll to position
    scrollContainer.scrollTo({
      top: Math.max(0, scrollPositionY),
      left: Math.max(0, scrollPositionX),
      behavior: 'smooth'
    })
  }
}