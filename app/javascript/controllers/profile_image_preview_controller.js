import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "attachedImage",
    "previewImage",
    "placeholderImage",
    "deleteProfileImage",
    "input",
    "clearBtn",
    "uploadText",
    "changeText",
    "cameraIcon"
  ];

  clearFileInput() {
    this.inputTarget.value = null;
    this.clearBtnTarget.classList.add("hidden");
    this.placeholderImageTarget.classList.remove("hidden");
    this.attachedImageTarget.classList.add("hidden");
    this.previewImageTarget.classList.add("hidden");
    this.deleteProfileImageTarget.value = "1";
    this.uploadTextTarget.classList.remove("hidden");
    this.changeTextTarget.classList.add("hidden");
    this.changeTextTarget.setAttribute("aria-hidden", "true");
    this.uploadTextTarget.setAttribute("aria-hidden", "false");
    this.cameraIconTarget.classList.remove("!hidden");

  }

  showFileInputPreview(event) {
    const file = event.target.files[0];
    if (!file) return;

    this.placeholderImageTarget.classList.add("hidden");
    this.attachedImageTarget.classList.add("hidden");
    this.previewImageTarget.classList.remove("hidden");
    this.clearBtnTarget.classList.remove("hidden");
    this.deleteProfileImageTarget.value = "0";
    this.uploadTextTarget.classList.add("hidden");
    this.changeTextTarget.classList.remove("hidden");
    this.changeTextTarget.setAttribute("aria-hidden", "false");
    this.uploadTextTarget.setAttribute("aria-hidden", "true");
    this.cameraIconTarget.classList.add("!hidden");
    this.previewImageTarget.querySelector("img").src =
      URL.createObjectURL(file);
  }
}
