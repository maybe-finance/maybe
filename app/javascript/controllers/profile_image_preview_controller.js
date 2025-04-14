import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "attachedImage",
    "previewImage",
    "placeholderImage",
    "deleteProfileImage",
    "input",
    "clearBtn",
  ];

  triggerFileInput() {
    this.inputTarget.click();
  }

  clearFileInput() {
    this.inputTarget.value = null;
    this.clearBtnTarget.classList.add("hidden");
    this.placeholderImageTarget.classList.remove("hidden");
    this.attachedImageTarget.classList.add("hidden");
    this.previewImageTarget.classList.add("hidden");
    this.deleteProfileImageTarget.value = "1";
  }

  showFileInputPreview(event) {
    const file = event.target.files[0];
    if (!file) return;

    this.placeholderImageTarget.classList.add("hidden");
    this.attachedImageTarget.classList.add("hidden");
    this.previewImageTarget.classList.remove("hidden");
    this.clearBtnTarget.classList.remove("hidden");
    this.deleteProfileImageTarget.value = "0";

    this.previewImageTarget.querySelector("img").src =
      URL.createObjectURL(file);
  }
}
