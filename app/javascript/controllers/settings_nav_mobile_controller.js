import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    setTimeout(() => {
      this.scrollToActiveItem()
    }, 100)
  }

  scrollToActiveItem() {
    const itemsContainer = this.element.querySelector('#settings-mobile-nav-items')
    const activeItem = itemsContainer?.querySelector('[aria-current="page"]')

    if (!activeItem) return

    const scrollContainer = this.element
    const containerRect = scrollContainer.getBoundingClientRect()
    const activeItemRect = activeItem.getBoundingClientRect()

    const scrollPosition = (activeItemRect.left + scrollContainer.scrollLeft) -
                          (containerRect.width / 2) +
                          (activeItemRect.width / 2)

    // Smooth scroll to position
    scrollContainer.scrollTo({
      left: Math.max(0, scrollPosition),
      behavior: 'smooth'
    })
  }
}