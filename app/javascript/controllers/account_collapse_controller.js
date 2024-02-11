import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="account-collapse"
export default class extends Controller {

	static values = { type: String }
	boundOnToggle = null
	initialToggle = false
	STORAGE_NAME = 'accountCollapseStates'

	connect() {
		this.boundOnToggle = this.onToggle.bind(this)
    this.element
      .addEventListener("toggle", this.boundOnToggle)
		this.updateFromLocalStorage()
  }

  disconnect() {
		this.element.removeEventListener("toggle", this.boundOnToggle)
	}

	onToggle() {
		if (this.initialToggle) {
      this.initialToggle = false
      return
    }
		
		const items = this.getItemsFromLocalStorage()
    if (items.has(this.typeValue)) {
			items.delete(this.typeValue)
		} else {
			items.add(this.typeValue)
		}
		localStorage.setItem(this.STORAGE_NAME, JSON.stringify([...items]))
	}

  updateFromLocalStorage() {
    const items = this.getItemsFromLocalStorage()
    
    if (items.has(this.typeValue)) {
			this.initialToggle = true
			this.element.setAttribute('open', '')
    }
  }

  getItemsFromLocalStorage() {
    try {
			const items = localStorage.getItem(this.STORAGE_NAME)
			return new Set(items ? JSON.parse(items) : [])
		} catch (error) {
			console.error("Error parsing items from localStorage:", error)
			return new Set()
		}
  }
}
