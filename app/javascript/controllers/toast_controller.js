import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toast"
export default class extends Controller {
  static targets = ["circle"]

  // time the toast was opened
  // used to calculate filled percentage of loading circle
  // automatically set by connect
  baseTime;

  // this tells the refresh loop to stop refreshing the circle when closing
  closing = false;

  // closes the toast gracefully
  closeToast() {
    this.closing = true;
    this.element.style.opacity = 0;
    setTimeout(() => {
      this.element.remove();
    }, 500);
  }

  connect() {
    // close toast when clicked
    this.element.addEventListener("click", this.closeToast.bind(this));

    this.baseTime = Date.now();

    // refresh loop: updates loading circle on every animation frame
    const doRefresh = () => {
      const progress = (Date.now() - this.baseTime) / 5000;

      if (progress < 1) {
        // stroke-dasharray is set up on HTML-side using static circle circumference
        // stroke-dashoffset = circumference * (1 - progress)
        this.circleTarget.style.strokeDashoffset = 45.238934 * (1 - progress);

        // Don't loop on next frame if toast is being closed
        if (!this.closing) {
          requestAnimationFrame(doRefresh);
        }
      } else {
        // if stroke-dashoffset = 0, progress circle is filled
        this.circleTarget.style.strokeDashoffset = 0;
        this.closeToast();
      }
    }

    // kickstart refresh loop
    doRefresh();
  }
}
