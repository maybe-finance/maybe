import { Controller } from "@hotwired/stimulus";

export default class FlashController extends Controller {
  static targets = ["circle"];

  // Keeps track of when the Flash was opened
  baseTime;

  // Indicates whether the Flash is being closed
  closing = false;

  // Closes the Flash gracefully
  closeFlash() {
    this.closing = true;
    // Set opacity to 0 for a fade-out effect
    this.element.style.opacity = 0;
    // Remove the element from the DOM after 500 milliseconds
    setTimeout(() => {
      this.element.remove();
    }, 500);
  }

  connect() {
    // Close Flash when clicked
    this.element.addEventListener("click", this.handleClick.bind(this));

    // Set the base time when the Flash is connected
    this.baseTime = Date.now();

    // Function to update loading circle on every animation frame
    const updateCircle = () => {
      // Calculate the progress based on the time elapsed since the Flash was opened
      const progress = (Date.now() - this.baseTime) / 5000;

      // If progress is less than 1, update the loading circle
      if (progress < 1) {
        // Calculate the new stroke-dashoffset value based on progress
        this.updateCircleAnimation(progress);

        // Continue updating if Flash is not being closed
        if (!this.closing) {
          requestAnimationFrame(updateCircle);
        }
      } else {
        // If progress is 1 or greater, fill the circle and close the Flash
        this.completeCircleAnimation();
        this.closeFlash();
      }
    };

    // Start the update loop
    updateCircle();
  }

  handleClick() {
    this.closeFlash();
  }

  updateCircleAnimation(progress) {
    this.circleTarget.style.strokeDashoffset = 45.238934 * (1 - progress);
  }

  completeCircleAnimation() {
    this.circleTarget.style.strokeDashoffset = 0;
  }
}
