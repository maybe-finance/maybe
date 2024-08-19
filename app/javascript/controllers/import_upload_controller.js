import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "submit", "filename", "filesize"]
  static values = {
    acceptedTypes: Array, // ["text/csv", "application/csv", ".csv"]
    acceptedExtension: String, // "csv"
    unacceptableTypeLabel: String, // "Only CSV files are allowed."
  };

  connect() {
    this.submitTarget.disabled = true
  }

  addFile(event) {
    const file = event.target.files[0]
    this._fileAdded(file)
  }

  dragover(event) {
    event.preventDefault()
    event.stopPropagation()
    event.currentTarget.classList.add("bg-gray-100")
  }

  dragleave(event) {
    event.preventDefault()
    event.stopPropagation()
    event.currentTarget.classList.remove("bg-gray-100")
  }

  drop(event) {
    event.preventDefault()
    event.stopPropagation()
    event.currentTarget.classList.remove("bg-gray-100")

    const file = event.dataTransfer.files[0]
    if (file && this._formatAcceptable(file)) {
      this._setFileInput(file);
      this._fileAdded(file)
    } else {
      this.previewTarget.classList.add("text-red-500")
      this.previewTarget.textContent = this.unacceptableTypeLabelValue
    }
  }

  click() {
    this.inputTarget.click();
  }

  // Private

  _fetchFileSize(size) {
    let fileSize = '';
    if (size < 1024 * 1024) {
      fileSize = (size / 1024).toFixed(2) + ' KB'; // Convert bytes to KB
    } else {
      fileSize = (size / (1024 * 1024)).toFixed(2) + ' MB'; // Convert bytes to MB
    }
    return fileSize;
  }

  _fileAdded(file) {
    const fileSizeLimit = 5 * 1024 * 1024 // 5MB

    if (file) {
      if (file.size > fileSizeLimit) {
        this.previewTarget.classList.add("text-red-500")
        this.previewTarget.textContent = this.unacceptableTypeLabelValue
        return
      }

      this.submitTarget.classList.remove([
        "bg-alpha-black-25",
        "text-gray",
        "cursor-not-allowed",
      ]);
      this.submitTarget.classList.add(
        "bg-gray-900",
        "text-white",
        "cursor-pointer",
      );
      this.submitTarget.disabled = false;
      this.previewTarget.innerHTML = document.querySelector("#template-preview").innerHTML;
      this.previewTarget.classList.remove("text-red-500")
      this.previewTarget.classList.add("text-gray-900")
      this.filenameTarget.textContent = file.name;
      this.filesizeTarget.textContent = this._fetchFileSize(file.size);
    }
  }

  _formatAcceptable(file) {
    const extension = file.name.split('.').pop().toLowerCase()
    return this.acceptedTypesValue.includes(file.type) || extension === this.acceptedExtensionValue
  }

  _setFileInput(file) {
    const dataTransfer = new DataTransfer();
    dataTransfer.items.add(file);
    this.inputTarget.files = dataTransfer.files;
  }
}
