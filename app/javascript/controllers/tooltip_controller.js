import { Controller } from '@hotwired/stimulus'
import {
  computePosition,
  flip,
  shift,
  offset,
  arrow
} from '@floating-ui/dom';

export default class extends Controller {
  static targets = ["arrow", "tooltip"];
  static values = {
    placement: { type: String, default: "top" },
    offset: { type: Number, default: 10 },
    crossAxis: { type: Number, default: 0 },
    alignmentAxis: { type: Number, default: null },
  };

  connect() {
    this.element.addEventListener("mouseenter", this.showTooltip);
    this.element.addEventListener("mouseleave", this.hideTooltip);
    this.element.addEventListener("focus", this.showTooltip);
    this.element.addEventListener("blur", this.hideTooltip);
  };

  showTooltip = () => {
    this.tooltipTarget.style.display = 'block';
    this.#update();
  };

  hideTooltip = () => {
    this.tooltipTarget.style.display = '';
  };

  disconnect() {
    this.element.removeEventListener("mouseenter", this.showTooltip);
    this.element.removeEventListener("mouseleave", this.hideTooltip);
    this.element.removeEventListener("focus", this.showTooltip);
    this.element.removeEventListener("blur", this.hideTooltip);
  };

  #update() {
    computePosition(this.element, this.tooltipTarget, {
      placement: this.placementValue,
      middleware: [
        offset({ mainAxis: this.offsetValue, crossAxis: this.crossAxisValue, alignmentAxis: this.alignmentAxisValue }),
        flip(),
        shift({ padding: 5 }),
        arrow({ element: this.arrowTarget }),
      ],
    }).then(({ x, y, placement, middlewareData }) => {
      Object.assign(this.tooltipTarget.style, {
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

      Object.assign(this.arrowTarget.style, {
        left: arrowX != null ? `${arrowX}px` : '',
        top: arrowY != null ? `${arrowY}px` : '',
        right: '',
        bottom: '',
        [staticSide]: '-4px',
      });
    });
  };
}
