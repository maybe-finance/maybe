import { Controller } from "@hotwired/stimulus"

/*
  https://dev.to/konnorrogers/maintain-scroll-position-in-turbo-without-data-turbo-permanent-2b1i
  modified to add support for horizontal scrolling

  only requirement is that the element has an id
 */
export default class extends Controller {
  static scrollPositions = {}

  connect() {
    this.preserveScrollBound = this.preserveScroll.bind(this)
    this.restoreScrollBound = this.restoreScroll.bind(this)

    window.addEventListener("turbo:before-cache", this.preserveScrollBound)
    window.addEventListener("turbo:before-render", this.restoreScrollBound)
    window.addEventListener("turbo:render", this.restoreScrollBound)
  }

  disconnect() {
    window.removeEventListener("turbo:before-cache", this.preserveScrollBound)
    window.removeEventListener("turbo:before-render", this.restoreScrollBound)
    window.removeEventListener("turbo:render", this.restoreScrollBound)
  }

  preserveScroll() {
    if (!this.element.id) return

    this.constructor.scrollPositions[this.element.id] = {
      top: this.element.scrollTop,
      left: this.element.scrollLeft
    }
  }

  restoreScroll(event) {
    if (!this.element.id) return

    if (this.constructor.scrollPositions[this.element.id]) {
      this.element.scrollTop = this.constructor.scrollPositions[this.element.id].top
      this.element.scrollLeft = this.constructor.scrollPositions[this.element.id].left
    }
  }
}