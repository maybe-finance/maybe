import { Controller } from '@hotwired/stimulus'
import {
  computePosition,
  flip,
  shift,
  offset,
  arrow
} from '@floating-ui/dom';

export default class extends Controller {
  static targets = ["element", "tooltip"];
  static values = {
    placement: String,
    offset: Number,
    crossAxis: Number
  };

  initialize() {
    this.placementOption = this.placementValue || "top"
    this.offsetOption = this.offsetValue || 10
    this.crossAxisOption = this.crossAxisValue || 0
    this.alignmentAxisOption = this.alignmentValue || null
    this.arrowElement = document.querySelector('#arrow');
  }

  connect() {
    this.elementTarget.addEventListener("mouseenter", this.showTooltip);
    this.elementTarget.addEventListener("mouseleave", this.hideTooltip);
    this.elementTarget.addEventListener("focus", this.showTooltip);
    this.elementTarget.addEventListener("blur", this.hideTooltip);
  }

  showTooltip = () => {
    tooltip.style.display = 'block';
    this.#update();
  }

  hideTooltip = () => {
    tooltip.style.display = '';
  }

  hideAllElements() {
    document.querySelectorAll('#tooltip').forEach(element => element.removeAttribute("data-show"));
  }

  disconnect() {
    hideAllElements();
  }

  #update() {
    computePosition(this.elementTarget, this.tooltipTarget, {
      placement: this.placementOption,
      middleware: [
        offset({ mainAxis: this.offsetOption, crossAxis: this.crossAxisOption, alignmentAxis: this.alignmentAxisOption }),
        flip(),
        shift({ padding: 5 }),
        arrow({ element: this.arrowElement }),
      ],
    }).then(({ x, y, placement, middlewareData }) => {
      Object.assign(tooltip.style, {
        left: `${x}px`,
        top: `${y}px`,
      });

      const { x: arrowX, y: arrowY } = middlewareData.arrow;
      const staticSide = {
        top: 'bottom',
        right: 'left',
        bottom: 'top',
        left: 'right',
      }[placement.split('-')[0]];

      Object.assign(this.arrowElement.style, {
        left: arrowX != null ? `${arrowX}px` : '',
        top: arrowY != null ? `${arrowY}px` : '',
        right: '',
        bottom: '',
        [staticSide]: '-4px',
      });
    });
  }
}
