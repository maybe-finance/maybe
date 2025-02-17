import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="color-avatar"
// Used by the transaction merchant form to show a preview of what the avatar will look like
export default class extends Controller {
  static targets = ["name", "avatar", "selection","colorInput"];

  connect() {
    if(!this.hasColorInputTarget){
      this.nameTarget.addEventListener("input", this.handleNameChange);
    }

    if(this.hasColorInputTarget){
      this.observer = new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
          if (mutation.type === "attributes" && mutation.attributeName === "data-color-picker-color-value") {
            const color = mutation.target.value;
            this.updateAvatarColors(color);
          }
        });
      });
  
      this.observer.observe(this.colorInputTarget, {
        attributes: true,
        attributeFilter: ["data-color-picker-color-value"]
      });
    }

  }

  disconnect() {
    if(this.hasColorInputTarget){
      this.observer.disconnect()
    }
    this.nameTarget.removeEventListener("input", this.handleNameChange);
  }

  handleNameChange = (e) => {
    this.avatarTarget.textContent = (
      e.currentTarget.value?.[0] || "?"
    ).toUpperCase();
  };

  handleIconChange(e) {
    const iconSVG = e.currentTarget.closest('label').querySelector('svg').cloneNode(true);
    this.avatarTarget.innerHTML = '';
    this.avatarTarget.appendChild(iconSVG);
  }

  updateAvatarColors(color) {
    this.avatarTarget.style.backgroundColor = `color-mix(in srgb, ${color} 5%, white)`;
    this.avatarTarget.style.borderColor = `color-mix(in srgb, ${color} 10%, white)`;
    this.avatarTarget.style.color = color;
  }

  handleColorChange(e) {
    const color = e.currentTarget.value;
    this.updateAvatarColors(color)
  }

  handleParentChange(e) {
    const parent = e.currentTarget.value;
    const display = typeof parent === "string" && parent !== "" ? "none" : "flex";
    this.selectionTarget.style.display = display;
  }
}
