import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="mobile-cell-interaction"
export default class extends Controller {
  static targets = ["field", "highlight", "errorTooltip", "errorIcon"];
  static values = { error: String };
  
  touchTimeout = null;
  activeTooltip = null;
  documentClickHandler = null;

  connect() {
    this.documentClickHandler = this.handleDocumentClick.bind(this);
    document.addEventListener('click', this.documentClickHandler);
  }

  disconnect() {
    if (this.documentClickHandler) {
      document.removeEventListener('click', this.documentClickHandler);
    }
  }

  handleDocumentClick(event) {
    if (event.target.closest('[data-mobile-cell-interaction-target="errorTooltip"]') || 
        event.target.closest('[data-mobile-cell-interaction-target="errorIcon"]')) {
      return;
    }
    
    this.hideAllErrorTooltips();
  }

  highlightCell(event) {
    const field = event.target;
    const highlight = this.findHighlightForField(field);
    if (highlight) {
      highlight.style.opacity = '1';
    }
  }
  
  unhighlightCell(event) {
    const field = event.target;
    const highlight = this.findHighlightForField(field);
    if (highlight) {
      highlight.style.opacity = '0';
    }
    
    this.hideAllErrorTooltips();
  }
  
  handleCellTouch(event) {
    if (this.touchTimeout) {
      clearTimeout(this.touchTimeout);
    }
    
    const field = event.target;
    
    const highlight = this.findHighlightForField(field);
    if (highlight) {
      highlight.style.opacity = '1';
      
      this.touchTimeout = window.setTimeout(() => {
        if (document.activeElement !== field) {
          highlight.style.opacity = '0';
        }
      }, 1000);
    }
    
    if (this.hasErrorValue && this.errorValue) {
      this.showErrorTooltip();
    }
  }
  
  toggleErrorMessage(event) {
    const errorIcon = event.currentTarget;
    const cellContainer = errorIcon.closest('div');
    const field = cellContainer.querySelector('input');
    
    if (field) {
      field.focus();
    }
    
    const tooltip = this.errorTooltipTarget;
    
    this.hideAllTooltipsExcept(tooltip);
    
    if (tooltip.classList.contains('hidden')) {
      tooltip.classList.remove('hidden');
      this.activeTooltip = tooltip;
      
      setTimeout(() => {
        if (tooltip === this.activeTooltip) {
          tooltip.classList.add('hidden');
          this.activeTooltip = null;
        }
      }, 3000);
    } else {
      tooltip.classList.add('hidden');
      this.activeTooltip = null;
    }
    
    event.stopPropagation();
  }
  
  showErrorTooltip() {
    if (this.hasErrorTooltipTarget) {
      const tooltip = this.errorTooltipTarget;
      tooltip.classList.remove('hidden');
      this.activeTooltip = tooltip;
      
      setTimeout(() => {
        if (tooltip === this.activeTooltip) {
          tooltip.classList.add('hidden');
          this.activeTooltip = null;
        }
      }, 3000);
    }
  }
  
  hideAllErrorTooltips() {
    document.querySelectorAll('[data-mobile-cell-interaction-target="errorTooltip"]').forEach(tooltip => {
      tooltip.classList.add('hidden');
    });
    this.activeTooltip = null;
  }
  
  hideAllTooltipsExcept(tooltipToKeep) {
    document.querySelectorAll('[data-mobile-cell-interaction-target="errorTooltip"]').forEach(tooltip => {
      if (tooltip !== tooltipToKeep) {
        tooltip.classList.add('hidden');
      }
    });
  }
  
  selectCell(event) {
    const errorIcon = event.currentTarget;
    const cellContainer = errorIcon.closest('div');
    const field = cellContainer.querySelector('input');
    
    if (field) {
      field.focus();
      event.stopPropagation();
    }
  }
  
  findHighlightForField(field) {
    const container = field.closest('div');
    return container ? container.querySelector('[data-mobile-cell-interaction-target="highlight"]') : null;
  }
} 