import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="account-list"
export default class extends Controller {
  getItem(key) {
    try {
      return JSON.parse(localStorage.getItem(key))
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
    const { accountType } = this.element.dataset
    let config = this.getItem('accountList')

    if (!config) config = {}

    config[accountType] = this.element.open
    this.setItem('accountList', config)
  }

  connect() {
    const { accountType } = this.element.dataset
    let config = this.getItem('accountList') || {}
    
    if (!config[accountType]) {
      config[accountType] = this.element.open
      this.setItem('accountList', config)
    } 
    
    this.element.open = config[accountType]
  }
}
