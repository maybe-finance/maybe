import { Controller } from "@hotwired/stimulus";

/**
 * A "listbox" is a custom "select" element that follows accessibility patterns of a native select element.
 *
 * - If you need to display arbitrary content including non-clickable items, links, buttons, and forms, use the "popover" controller instead.
 */
export default class extends Controller {
  static classes = ["active"];
  static targets = ["option", "button", "list", "input"];

  connect() {
    this.show = false;
    this.syncButtonTextWithInput();
    this.listTarget.classList.add("hidden");
    this.element.addEventListener("keydown", this.handleKeydown);
    document.addEventListener("click", this.handleOutsideClick);
  }

  disconnect() {
    this.element.removeEventListener("keydown", this.handleKeydown);
    document.removeEventListener("click", this.handleOutsideClick);
  }

  handleOutsideClick = (event) => {
    if (this.show && !this.element.contains(event.target)) {
      this.close();
    }
  };

  handleKeydown = (event) => {
    switch (event.key) {
      case " ":
      case "Enter":
        event.preventDefault(); // Prevent the default action to avoid scrolling
        if (document.activeElement === this.buttonTarget) {
          this.toggleList();
        } else {
          this.selectOption(event);
        }
        break;
      case "ArrowDown":
        event.preventDefault(); // Prevent the default action to avoid scrolling
        this.focusNextOption();
        break;
      case "ArrowUp":
        event.preventDefault(); // Prevent the default action to avoid scrolling
        this.focusPreviousOption();
        break;
      case "Escape":
        this.close();
        this.buttonTarget.focus(); // Bring focus back to the button
        break;
      case "Tab":
        this.close();
        break;
    }
  };

  focusNextOption() {
    this.focusOptionInDirection(1);
  }

  focusPreviousOption() {
    this.focusOptionInDirection(-1);
  }

  focusOptionInDirection(direction) {
    const currentFocusedIndex = this.optionTargets.findIndex(
      (option) => option === document.activeElement
    );
    const optionsCount = this.optionTargets.length;
    const nextIndex =
      (currentFocusedIndex + direction + optionsCount) % optionsCount;
    this.optionTargets[nextIndex].focus();
  }

  toggleList() {
    this.show = !this.show;
    this.listTarget.classList.toggle("hidden", !this.show);
    this.buttonTarget.setAttribute("aria-expanded", this.show.toString());

    if (this.show) {
      // Focus the first option or the selected option when the list is shown
      const selectedOption = this.optionTargets.find(
        (option) => option.getAttribute("aria-selected") === "true"
      );
      (selectedOption || this.optionTargets[0]).focus();
    }
  }

  close() {
    this.show = false;
    this.listTarget.classList.add("hidden");
    this.buttonTarget.setAttribute("aria-expanded", "false");
  }

  selectOption(event) {
    const selectedOption =
      event.type === "keydown" ? document.activeElement : event.currentTarget;
    this.optionTargets.forEach((option) => {
      option.setAttribute("aria-selected", "false");
      option.setAttribute("tabindex", "-1");
      option.classList.remove(...this.activeClasses);
    });
    selectedOption.classList.add(...this.activeClasses);
    selectedOption.setAttribute("aria-selected", "true");
    selectedOption.focus();
    this.toggleList(false); // Close the list after selection

    // Update the hidden input's value
    const selectedValue = selectedOption.getAttribute("data-value");
    this.inputTarget.value = selectedValue;
    this.syncButtonTextWithInput();
  }

  syncButtonTextWithInput() {
    const matchingOption = this.optionTargets.find(
      (option) => option.getAttribute("data-value") === this.inputTarget.value
    );
    if (matchingOption) {
      this.buttonTarget.textContent = matchingOption.textContent.trim();
    }
  }
}
