import { Controller } from "@hotwired/stimulus";
import Pickr from "@simonwep/pickr";

export default class extends Controller {
  static targets = [
    "pickerBtn",
    "colorInput",
    "colorsSection",
    "paletteSection",
    "pickerSection",
    "colorPreview",
    "avatar",
    "details",
    "icon",
    "validationMessage",
    "selection",
    "colorPickerRadioBtn",
    "popup",
  ];

  static values = {
    presetColors: Array,
  };

  initialize() {
    this.pickerBtnTarget.addEventListener("click", () => {
      this.showPaletteSection();
    });

    this.colorInputTarget.addEventListener("input", (e) => {
      this.picker.setColor(e.target.value);
    });

    this.detailsTarget.addEventListener("toggle", (e) => {
      if (!this.colorInputTarget.checkValidity()) {
        e.preventDefault();
        this.colorInputTarget.reportValidity();
        e.target.open = true;
      }
      this.updatePopupPosition()
    });

    this.selectedIcon = null;

    if (!this.presetColorsValue.includes(this.colorInputTarget.value)) {
      this.colorPickerRadioBtnTarget.checked = true;
    }

    document.addEventListener("mousedown", this.handleOutsideClick);
  }

  initPicker() {
    const pickerContainer = document.createElement("div");
    pickerContainer.classList.add("pickerContainer");
    this.pickerSectionTarget.append(pickerContainer);

    this.picker = Pickr.create({
      el: this.pickerBtnTarget,
      theme: "monolith",
      container: ".pickerContainer",
      useAsButton: true,
      showAlways: true,
      default: this.colorInputTarget.value,
      components: {
        hue: true,
      },
    });

    this.picker.on("change", (color) => {
      const hexColor = color.toHEXA().toString();
      const rgbacolor = color.toRGBA();

      this.updateAvatarColors(hexColor);
      this.updateSelectedIconColor(hexColor);

      const backgroundColor = this.backgroundColor(rgbacolor, 10);
      const contrastRatio = this.contrast(rgbacolor, backgroundColor);

      this.colorInputTarget.value = hexColor;
      this.colorInputTarget.dataset.colorPickerColorValue = hexColor;
      this.colorPreviewTarget.style.backgroundColor = hexColor;

      this.handleContrastValidation(contrastRatio);
    });
  }

  updateAvatarColors(color) {
    this.avatarTarget.style.backgroundColor = `${this.#backgroundColor(color)}`;
    this.avatarTarget.style.color = color;
  }

  handleIconColorChange(e) {
    const selectedIcon = e.target;
    this.selectedIcon = selectedIcon;

    const currentColor = this.colorInputTarget.value;

    this.iconTargets.forEach((icon) => {
      const iconWrapper = icon.nextElementSibling;
      iconWrapper.style.removeProperty("background-color");
      iconWrapper.style.removeProperty("color");
    });

    this.updateSelectedIconColor(currentColor);
  }

  handleIconChange(e) {
    const iconSVG = e.currentTarget
      .closest("label")
      .querySelector("svg")
      .cloneNode(true);
    this.avatarTarget.innerHTML = "";
    iconSVG.style.padding = "0px";
    iconSVG.classList.add("w-8", "h-8");
    this.avatarTarget.appendChild(iconSVG);
  }

  updateSelectedIconColor(color) {
    if (this.selectedIcon) {
      const iconWrapper = this.selectedIcon.nextElementSibling;
      iconWrapper.style.backgroundColor = `${this.#backgroundColor(color)}`;
      iconWrapper.style.color = color;
    }
  }

  handleColorChange(e) {
    const color = e.currentTarget.value;
    this.colorInputTarget.value = color;
    this.colorPreviewTarget.style.backgroundColor = color;
    this.updateAvatarColors(color);
    this.updateSelectedIconColor(color);
  }

  handleContrastValidation(contrastRatio) {
    if (contrastRatio < 4.5) {
      this.colorInputTarget.setCustomValidity(
        "Poor contrast, choose darker color or auto-adjust.",
      );

      this.validationMessageTarget.classList.remove("hidden");
    } else {
      this.colorInputTarget.setCustomValidity("");
      this.validationMessageTarget.classList.add("hidden");
    }
  }

  autoAdjust(e) {
    const currentRGBA = this.picker.getColor();
    const adjustedRGBA = this.darkenColor(currentRGBA).toString();
    this.picker.setColor(adjustedRGBA);
  }

  handleParentChange(e) {
    const parent = e.currentTarget.value;
    const display =
      typeof parent === "string" && parent !== "" ? "none" : "flex";
    this.selectionTarget.style.display = display;
  }

  backgroundColor([r, g, b, a], percentage) {
    const mixedR = Math.round(
      r * (percentage / 100) + 255 * (1 - percentage / 100),
    );
    const mixedG = Math.round(
      g * (percentage / 100) + 255 * (1 - percentage / 100),
    );
    const mixedB = Math.round(
      b * (percentage / 100) + 255 * (1 - percentage / 100),
    );
    return [mixedR, mixedG, mixedB];
  }

  luminance([r, g, b]) {
    const toLinear = (c) => {
      const scaled = c / 255;
      return scaled <= 0.04045
        ? scaled / 12.92
        : ((scaled + 0.055) / 1.055) ** 2.4;
    };
    return 0.2126 * toLinear(r) + 0.7152 * toLinear(g) + 0.0722 * toLinear(b);
  }

  contrast(foregroundColor, backgroundColor) {
    const fgLum = this.luminance(foregroundColor);
    const bgLum = this.luminance(backgroundColor);
    const [l1, l2] = [Math.max(fgLum, bgLum), Math.min(fgLum, bgLum)];
    return (l1 + 0.05) / (l2 + 0.05);
  }

  darkenColor(color) {
    let darkened = color.toRGBA();
    const backgroundColor = this.backgroundColor(darkened, 10);
    let contrastRatio = this.contrast(darkened, backgroundColor);

    while (
      contrastRatio < 4.5 &&
      (darkened[0] > 0 || darkened[1] > 0 || darkened[2] > 0)
    ) {
      darkened = [
        Math.max(0, darkened[0] - 10),
        Math.max(0, darkened[1] - 10),
        Math.max(0, darkened[2] - 10),
        darkened[3],
      ];
      contrastRatio = this.contrast(darkened, backgroundColor);
    }

    return `rgba(${darkened.join(", ")})`;
  }

  showPaletteSection() {
    this.initPicker();
    this.colorsSectionTarget.classList.add("hidden");
    this.paletteSectionTarget.classList.remove("hidden");
    this.pickerSectionTarget.classList.remove("hidden");
    this.updatePopupPosition();
    this.picker.show();
  }

  showColorsSection() {
    this.colorsSectionTarget.classList.remove("hidden");
    this.paletteSectionTarget.classList.add("hidden");
    this.pickerSectionTarget.classList.add("hidden");
    this.updatePopupPosition()
    if (this.picker) {
      this.picker.destroyAndRemove();
    }
  }

  toggleSections() {
    if (this.colorsSectionTarget.classList.contains("hidden")) {
      this.showColorsSection();
    } else {
      this.showPaletteSection();
    }
  }

  handleOutsideClick = (event) => {
    if (this.detailsTarget.open && !this.detailsTarget.contains(event.target)) {
      this.detailsTarget.open = false;
    }
  };

  updatePopupPosition() {
    const popup = this.popupTarget;
    popup.style.top = "";
    popup.style.bottom = "";

    const rect = popup.getBoundingClientRect();
    const overflow = rect.bottom > window.innerHeight;

    if (overflow) {
      popup.style.bottom = "0px";
    } else {
      popup.style.bottom = "";
    }
  }

  #backgroundColor(color) {
    return `color-mix(in oklab, ${color} 10%, transparent)`;
  }
}
