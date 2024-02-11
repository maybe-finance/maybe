import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="account-collapse"
export default class extends Controller {

	static values = { type: String }
	boundOnToggle = null;
	initialToggle = false;

	connect() {
		this.boundOnToggle = this.onToggle.bind(this)
    this.element
      .addEventListener("toggle", this.boundOnToggle)
		this.updateFromLocalStorage();
  }

  disconnect() {
		this.element.removeEventListener("toggle", this.boundOnToggle)
	}

	onToggle() {
		if (this.initialToggle) {
      this.initialToggle = false
      return;
    }
		
		const items = this.getItemsFromLocalStorage()
    if (items.has(this.typeValue)) {
			items.delete(this.typeValue)
		} else {
			items.add(this.typeValue)
		}
		localStorage.setItem('accountCollapseStates', JSON.stringify([...items]))
	}

  updateFromLocalStorage() {
    const items = this.getItemsFromLocalStorage()
    
    if (items.has(this.typeValue)) {
			this.initialToggle = true
			this.element.setAttribute('open', '')
    }
  }

  getItemsFromLocalStorage() {
    const items = localStorage.getItem('accountCollapseStates')
		return new Set(items ? JSON.parse(items) : [])
  }
}
