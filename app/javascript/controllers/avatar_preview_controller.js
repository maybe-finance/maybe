import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["preview"]

  loadPreview(event) {
    const input = event.target
    const reader = new FileReader()

    reader.onload = (e) => {
      this.previewTarget.src = e.currentTarget.result
    }

    if (input.files && input.files[0]) {
      reader.readAsDataURL(input.files[0])
    }
  }

  removeAvatar(event) {
    const input = event.target
    const reader = new FileReader()

    reader.onload = (e) => {
      this.previewTarget.src = "";
    }

  }
}
