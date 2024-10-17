import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["source", "iconDefault", "iconSuccess"];

  copy(event) {
    event.preventDefault();
    if (this.sourceTarget?.textContent) {
      navigator.clipboard
        .writeText(this.sourceTarget.textContent)
        .then(() => {
          this.showSuccess();
        })
        .catch((error) => {
          console.error("Failed to copy text: ", error);
        });
    }
  }

  showSuccess() {
    this.iconDefaultTarget.classList.add("hidden");
    this.iconSuccessTarget.classList.remove("hidden");
    setTimeout(() => {
      this.iconDefaultTarget.classList.remove("hidden");
      this.iconSuccessTarget.classList.add("hidden");
    }, 3000);
  }
}
