import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="account-list"
export default class extends Controller {
  static values = { category: String }

  getItem(key) {
    try {
      return JSON.parse(localStorage.getItem(key)) ?? {}
    } catch(err) {
      console.err('Error retrieving from localstorage', err)
      return null
    }
  }
  
  setItem(key, value) {
    try {
      localStorage.setItem(key, JSON.stringify(value))
    } catch(err) {
      console.err('Error writing to localstorage', err)
    }
  }
  
  handleToggle() {
    let config = this.getItem('accountList')

    config[this.categoryValue] = this.element.open
    this.setItem('accountList', config)
  }

  connect() {
    let config = this.getItem('accountList')
    
    if (!config.hasOwnProperty(this.categoryValue)) {
      config[this.categoryValue] = this.element.open
      this.setItem('accountList', config)
    } 
    
    this.element.open = config[this.categoryValue]
  }
}
