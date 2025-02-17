import { Controller } from "@hotwired/stimulus"
import Pickr from '@simonwep/pickr'

// Connects to data-controller="color-picker"
export default class extends Controller {
  static targets = ["pickerBtn", "colorInput", "colorsSection", "paletteSection", "pickerSection", "colorPreview"];

  initialize() {
    this.pickerBtnTarget.addEventListener('click', () => {
      this.showPaletteSection();
    });
    this.colorInputTarget.addEventListener('input', (e) => {
      this.picker.setColor(e.target.value);
    });
    this.element.parentElement.addEventListener('toggle', (e) => {
      if (!this.colorInputTarget.checkValidity()) {
        e.preventDefault();
        this.colorInputTarget.reportValidity();
        e.target.open = true;
      }
    })
  }

  initPicker() {
    const pickerContainer = document.createElement("div")
    pickerContainer.classList.add("pickerContainer")
    this.pickerSectionTarget.append(pickerContainer)
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

    this.picker.on('change', (color, source, instance) => {
      const hexColor = color.toHEXA().toString();
      const rgbacolor = color.toRGBA();

      const backgroundColor = this.backgroundColor(rgbacolor,5);
      const contrastRatio = this.contrast(rgbacolor, backgroundColor);

      this.colorInputTarget.value = hexColor;
      this.colorInputTarget.dataset.colorPickerColorValue = hexColor;
      this.colorPreviewTarget.style.backgroundColor = hexColor;

      if(contrastRatio < 4.5){
        this.colorInputTarget.setCustomValidity("Contrast ratio too low");
        this.colorInputTarget.parentElement.style.border = "2px solid var(--color-destructive)";
        if(this.paletteSectionTarget.querySelector("span")) return;

        const span = document.createElement("span");
        span.style.color = "var(--color-destructive)"
        span.textContent = "Choose a darker color";
        this.paletteSectionTarget.prepend(span);
      } else{
        this.colorInputTarget.setCustomValidity("");
        this.colorInputTarget.parentElement.style.border = "1px solid var(--color-alpha-black-100)";
        const span = this.paletteSectionTarget.querySelector("span");
        if (span) span.remove();
      }
    });
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

  handleColorChange(e) {
    const color = e.currentTarget.value;
    this.colorInputTarget.value = color;
    this.colorPreviewTarget.style.backgroundColor = color;
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