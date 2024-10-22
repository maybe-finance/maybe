import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "imagePreview",
    "emptyTemplate",
    "fileField",
    "deleteField",
    "clearBtn",
    "template",
  ];

  preview(event) {
    const file = event.target.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = (e) => {
        this.imagePreviewTarget.innerHTML = `<img src="${e.target.result}" alt="Preview" class="w-full h-full rounded-full object-cover" />`;
        this.templateTarget.classList.add("hidden");
        this.clearBtnTarget.classList.remove("hidden");
      };
      reader.readAsDataURL(file);
    }
  }

  clear() {
    this.deleteFieldTarget.value = true;
    this.fileFieldTarget.value = null;
    this.templateTarget.classList.remove("hidden");
    this.imagePreviewTarget.innerHTML = this.templateTarget.innerHTML;
    this.clearBtnTarget.classList.add("hidden");
    this.element.submit();
  }
}
