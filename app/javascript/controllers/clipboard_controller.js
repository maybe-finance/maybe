import { Controller } from "@hotwired/stimulus"


export default class extends Controller {
  static targets = ["source", "iconDefault", "iconSuccess"]

  connect() {
    console.log('Clipboard controller connected');
  }

  copy(event) {
    event.preventDefault();
    if (this.sourceTarget && this.sourceTarget.value) {
      navigator.clipboard.writeText(this.sourceTarget.value)
        .then(() => {
          this.showSuccess();
        })
        .catch((error) => {
          console.error('Failed to copy text: ', error);
        });
    }
  }

  showSuccess() {
    this.iconDefaultTarget.classList.add('hidden');
    this.iconSuccessTarget.classList.remove('hidden');
    setTimeout(() => {
      this.iconDefaultTarget.classList.remove('hidden');
      this.iconSuccessTarget.classList.add('hidden');
    }, 3000);
  }
}