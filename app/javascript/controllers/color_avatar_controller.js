import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="color-avatar"
// Used by the transaction merchant form to show a preview of what the avatar will look like
export default class extends Controller {
  static targets = ["name", "avatar", "selection"];

  connect() {
    this.nameTarget.addEventListener("input", this.handleNameChange);
  }

  disconnect() {
    this.nameTarget.removeEventListener("input", this.handleNameChange);
  }

  handleNameChange = (e) => {
    this.avatarTarget.textContent = (
      e.currentTarget.value?.[0] || "?"
    ).toUpperCase();
  };

  handleColorChange(e) {
    const color = e.currentTarget.value;
    this.avatarTarget.style.backgroundColor = `color-mix(in srgb, ${color} 5%, white)`;
    this.avatarTarget.style.borderColor = `color-mix(in srgb, ${color} 10%, white)`;
    this.avatarTarget.style.color = color;
  }

  handleParentChange(e) {
    const parent = e.currentTarget.value;
    const visibility = typeof parent === "string" && parent !== "" ? "hidden" : "visible"
    this.selectionTarget.style.visibility = visibility
  }
}
