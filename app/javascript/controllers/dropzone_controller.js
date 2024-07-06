import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";

// Connects to data-controller="dropzone"
export default class extends Controller {
  static targets = [
    "fileInput",
    "wrapper",
    "progressWrapper",
    "errorWrapper",
    "readyWrapper",
    "cancelButton",
    "successIcon",
    "tryAgainButton",
  ];
  static classes = ["dragOver"];
  static values = { url: String };

  connect() {
    this.element.addEventListener("dragover", this.preventDragDefaults);
    this.element.addEventListener("dragenter", this.preventDragDefaults);

    this.element.addEventListener("dragover", this._dragOverStyle.bind(this)); // Style dropzone when dragging over
    this.element.addEventListener("dragleave", this._dragLeaveStyle.bind(this)); // Remove styling from dropzone
  }

  disconnect() {
    this.element.removeEventListener("dragover", this.preventDragDefaults);
    this.element.removeEventListener("dragenter", this.preventDragDefaults);
  }

  preventDragDefaults(e) {
    e.preventDefault();
    e.stopPropagation();
  }

  trigger() {
    this.fileInputTarget.click();
  }

  acceptFiles(event) {
    event.preventDefault();
    const files = event.dataTransfer
      ? event.dataTransfer.files
      : event.target.files;

    const file = files[0];
    this._uploadFile(file);
  }

  _setupCancelButton(xhr) {
    this.cancelButtonTarget.addEventListener(
      "click",
      (e) => {
        e.stopPropagation();

        xhr.abort();
        this._cancelUpload();
      },
      { once: true }
    );
  }

  _setupTryAgainButton(xhr) {
    this.tryAgainButtonTarget.addEventListener(
      "click",
      (e) => {
        e.stopPropagation();

        xhr.abort();
        this._cancelUpload();
      },
      { once: true }
    );
  }

  // The actual cancelling of the upload, which handles resetting state.
  _cancelUpload() {
    this.readyWrapperTarget.classList.remove("hidden");
    this.progressWrapperTarget.classList.add("hidden");
    this.errorWrapperTarget.classList.add("hidden");
    this._resetProgress();
  }

  // Implement your own file upload strategy here...
  _uploadFile(file) {
    this.element.classList.remove(this.dragOverClass);
    this._createXmlHttpRequest(file);
  }

  _createXmlHttpRequest(file) {
    const xhr = new XMLHttpRequest();

    xhr.upload.addEventListener("loadstart", () => {
      this._changeToProgress(file.name);
    });

    xhr.upload.addEventListener("progress", (event) => {
      this._updateProgress(event);
    });

    xhr.onreadystatechange = () => {
      if (xhr.readyState === XMLHttpRequest.DONE) {
        if (xhr.status < 300) {
          Turbo.renderStreamMessage(xhr.responseText);
          this._changeToSuccess(file.name);
          return;
        }

        const response = JSON.parse(xhr.responseText);
        if (xhr.status === 400) {
          console.error(
            `A bad request was provided, this is most likely due to wrong file format.\nError message: "${response.message}"\nActual error: "${response.error}"`
          );
          this._changeToError();
        } else if (xhr.status === 422) {
          console.error("Uploaded CSV is not valid", response.message);
          this._changeToError();
        }
      }
    };

    const fileData = new FormData();
    fileData.append("file", file);

    xhr.open("POST", this.urlValue);

    this._setupCancelButton(xhr);
    this._setupTryAgainButton(xhr);

    xhr.send(fileData);
  }

  _dragOverStyle(e) {
    e.stopPropagation();
    this.element.classList.add(this.dragOverClass);
  }

  _dragLeaveStyle(e) {
    e.stopPropagation();
    this.element.classList.remove(this.dragOverClass);
  }

  _changeToProgress(fileName) {
    this.readyWrapperTarget.classList.add("hidden");
    this.progressWrapperTarget.classList.remove("hidden");

    this.progressWrapperTarget.children[1].innerText = `Uploading ${fileName}`;
    this.progressWrapperTarget.children[2].children[0].style.width = "0%";
    this.progressWrapperTarget.children[3].innerText = "0%";

    this.wrapperTarget.disabled = true;
  }

  _updateProgress(event) {
    const progress = ((event.loaded / event.total) * 100).toFixed(2);
    this.progressWrapperTarget.children[2].children[0].style.width = `${progress}%`;
    this.progressWrapperTarget.children[3].innerText = `${Math.round(
      progress
    )}%`;
  }

  _resetProgress() {
    this.progressWrapperTarget.children[1].innerText = "";
    this.progressWrapperTarget.children[2].children[0].style.width = "0%";

    this.wrapperTarget.disabled = false;

    this.successIconTarget.classList.add("hidden");
  }

  _changeToSuccess(fileName) {
    this.successIconTarget.classList.remove("hidden");
    this.progressWrapperTarget.children[1].innerText = `Succesfully uploaded ${fileName}`;
  }

  _changeToError() {
    this.errorWrapperTarget.classList.remove("hidden");
    this.progressWrapperTarget.classList.add("hidden");
    this._resetProgress();
    this.wrapperTarget.disabled = true;
  }
}
