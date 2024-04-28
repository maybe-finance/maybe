import {Controller} from "@hotwired/stimulus";

// Connects to data-controller="merchant-avatar"
// Used by the transaction merchant form to show a preview of what the avatar will look like
export default class extends Controller {
  static targets = [
    "name",
    "color",
    "avatar"
  ];

  connect() {
    this.nameTarget.addEventListener("input", this.handleNameChange);
    this.colorTarget.addEventListener("input", this.handleColorChange);
  }

  disconnect() {
    this.nameTarget.removeEventListener("input", this.handleNameChange);
    this.colorTarget.removeEventListener("input", this.handleColorChange);
  }

  handleNameChange = (e) => {
    this.avatarTarget.textContent = (e.currentTarget.value?.[0] || "?").toUpperCase();
  }

  handleColorChange = (e) => {
    const color = e.currentTarget.value;
    this.avatarTarget.style.backgroundColor = `color-mix(in srgb, ${color} 5%, white)`;
    this.avatarTarget.style.borderColor = `color-mix(in srgb, ${color} 10%, white)`;
    this.avatarTarget.style.color = color;
  }
}
