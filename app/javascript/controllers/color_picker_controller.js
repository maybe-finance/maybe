import { Controller } from "@hotwired/stimulus"
import Pickr from '@simonwep/pickr'

export default class extends Controller {
  static targets = ["pickerBtn", "colorInput", "colorsSection", "paletteSection", "pickerSection", "colorPreview", "avatar", "details", "icon"];

  initialize() {
    this.pickerBtnTarget.addEventListener('click', () => {
      this.showPaletteSection();
    });

    this.colorInputTarget.addEventListener('input', (e) => {
      this.picker.setColor(e.target.value);
    });

    this.detailsTarget.addEventListener('toggle', (e) => {
      if (!this.colorInputTarget.checkValidity()) {
        e.preventDefault();
        this.colorInputTarget.reportValidity();
        e.target.open = true;
      }
    });

    this.selectedIcon = null;
  }

  initPicker() {
    const pickerContainer = document.createElement("div");
    pickerContainer.classList.add("pickerContainer");
    this.pickerSectionTarget.append(pickerContainer);

    this.picker = Pickr.create({
      el: this.pickerBtnTarget,
      theme: 'monolith',
      container: ".pickerContainer",
      useAsButton: true,
      showAlways: true,
      default: this.colorInputTarget.value,
      components: {
        hue: true,
      },
    });

    this.picker.on('change', (color) => {
      const hexColor = color.toHEXA().toString();
      let rgbacolor = color.toRGBA();

      this.updateAvatarColors(hexColor);
      this.updateSelectedIconColor(hexColor);
      
      const backgroundColor = this.backgroundColor(rgbacolor, 5);
      const contrastRatio = this.contrast(rgbacolor, backgroundColor);

      this.colorInputTarget.value = hexColor;
      this.colorInputTarget.dataset.colorPickerColorValue = hexColor;
      this.colorPreviewTarget.style.backgroundColor = hexColor;

      this.handleContrastValidation(contrastRatio, rgbacolor);
    });
  }

  updateAvatarColors(color) {
    this.avatarTarget.style.backgroundColor = `color-mix(in srgb, ${color} 5%, white)`;
    this.avatarTarget.style.borderColor = `color-mix(in srgb, ${color} 10%, white)`;
    this.avatarTarget.style.color = color;
  }

  handleIconColorChange(e) {
    const selectedIcon = e.target;
    this.selectedIcon = selectedIcon;
    
    const currentColor = this.colorInputTarget.value;
    
    this.iconTargets.forEach(icon => {
      const iconWrapper = icon.nextElementSibling;
      iconWrapper.style.removeProperty("background-color")
      iconWrapper.style.color = "black";
      iconWrapper.classList.add(`hover:bg-[${currentColor}]`)
    });

    this.updateSelectedIconColor(currentColor);
  }

  handleIconChange(e) {
    const iconSVG = e.currentTarget.closest('label').querySelector('svg').cloneNode(true);
    this.avatarTarget.innerHTML = '';
    iconSVG.style.padding = "0px"
    this.avatarTarget.appendChild(iconSVG);
  }

  updateSelectedIconColor(color) {
    if (this.selectedIcon) {
      const iconWrapper = this.selectedIcon.nextElementSibling;
      iconWrapper.style.backgroundColor = `color-mix(in srgb, ${color} 15%, white)`;
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

  handleContrastValidation(contrastRatio, rgbacolor) {
    if (contrastRatio < 4.5) {
      this.colorInputTarget.setCustomValidity("Poor contrast, choose darker color or auto-adjust.");

      if (this.paletteSectionTarget.querySelector("span")) return;

      const darkColor = this.darkenColor(rgbacolor).toString();
      
      const span = document.createElement("span");
      span.style.color = "var(--color-destructive)";
      span.style.alignSelf = "start";
      span.classList.add("text-sm");
      span.innerHTML = "Poor contrast, choose darker color or ";

      const button = document.createElement("button");
      button.textContent = "auto-adjust.";
      button.type = "button";
      button.style.textDecoration = "underline";
      button.style.cursor = "pointer";

      button.addEventListener("click", () => {
        this.colorInputTarget.value = darkColor;
        this.colorInputTarget.dataset.colorPickerColorValue = darkColor;
        this.colorPreviewTarget.style.backgroundColor = darkColor;
        this.picker.setColor(darkColor);
        this.colorInputTarget.setCustomValidity("");

        const span = this.paletteSectionTarget.querySelector("span");
        if (span) span.remove();
      });

      span.appendChild(button);
      this.paletteSectionTarget.append(span);
    } else {
      this.colorInputTarget.setCustomValidity("");
      const span = this.paletteSectionTarget.querySelector("span");
      if (span) span.remove();
    }
  }

  backgroundColor([r,g,b,a], percentage) {
    const mixedR = Math.round((r * (percentage / 100)) + (255 * (1 - percentage / 100)));
    const mixedG = Math.round((g * (percentage / 100)) + (255 * (1 - percentage / 100)));
    const mixedB = Math.round((b * (percentage / 100)) + (255 * (1 - percentage / 100)));
    return [mixedR, mixedG, mixedB];
  }

  luminance([r,g,b]) {
    const toLinear = c => {
      const scaled = c / 255;
      return scaled <= 0.04045 
        ? scaled / 12.92 
        : Math.pow((scaled + 0.055) / 1.055, 2.4);
    };
    return 0.2126 * toLinear(r) + 0.7152 * toLinear(g) + 0.0722 * toLinear(b);
  }

  contrast(foregroundColor, backgroundColor) {
    const fgLum = this.luminance(foregroundColor);
    const bgLum = this.luminance(backgroundColor);
    const [l1, l2] = [Math.max(fgLum, bgLum), Math.min(fgLum, bgLum)];
    return (l1 + 0.05) / (l2 + 0.05);
  }

  darkenColor([r, g, b, a]) {
    let darkened = [r, g, b, a];
    let backgroundColor = this.backgroundColor(darkened, 5);
    let contrastRatio = this.contrast(darkened, backgroundColor);

    while (contrastRatio < 4.5 && (darkened[0] > 0 || darkened[1] > 0 || darkened[2] > 0)) {
      darkened = [
        Math.max(0, darkened[0] - 5),
        Math.max(0, darkened[1] - 5),
        Math.max(0, darkened[2] - 5),
        darkened[3]
      ];
      contrastRatio = this.contrast(darkened, backgroundColor);
    }

    const toHex = (n) => {
      const hex = Math.round(n).toString(16);
      return hex.length === 1 ? '0' + hex : hex;
    };

    return `#${toHex(darkened[0])}${toHex(darkened[1])}${toHex(darkened[2])}`;
  }

  showPaletteSection() {
    this.initPicker();
    this.colorsSectionTarget.classList.add('hidden');
    this.paletteSectionTarget.classList.remove('hidden');
    this.pickerSectionTarget.classList.remove('hidden');
    this.picker.show();
  }

  showColorsSection() {
    this.colorsSectionTarget.classList.remove('hidden');
    this.paletteSectionTarget.classList.add('hidden');
    this.pickerSectionTarget.classList.add('hidden');
    if (this.picker) {
      this.picker.destroyAndRemove();
    }
  }

  toggleSections() {
    if (this.colorsSectionTarget.classList.contains('hidden')) {
      this.showColorsSection();
    } else {
      this.showPaletteSection();
    }
  }
}