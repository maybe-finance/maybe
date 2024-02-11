import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="details-state"
export default class extends Controller {
  static values = { storageKey: String }

  initialize()  {
    this.localStorageSupported = this.isLocalStorageSupported()
    this.id = this.element.id
  }

  // Verify that localstorage is enabled in browser
  isLocalStorageSupported(){
    try {
      const storage = window['localStorage']
      const test = 'localstorage'

      storage.setItem(test, test)
      storage.removeItem(test)

      return true
    } catch(err) {
        console.error('Error connecting to localstorage', err)
        return false
    }
  }

  getItem(key) {
    try {
      return JSON.parse(localStorage.getItem(key)) ?? {}
    } catch(err) {
      console.error('Error retrieving from localstorage', err)
      return null
    }
  }
  
  setItem(key, value) {
    try {
      localStorage.setItem(key, JSON.stringify(value))
    } catch(err) {
      console.error('Error writing to localstorage', err)
    }
  }
  
  handleToggle() {
    if(!this.localStorageSupported) return

    let config = this.getItem(this.storageKeyValue)

    config[this.id] = this.element.open
    this.setItem(this.storageKeyValue, config)
  }

  connect() {
    if(!this.localStorageSupported) return

    let config = this.getItem(this.storageKeyValue)
    
    if (!config.hasOwnProperty(this.id)) {
      config[this.id] = this.element.open
      this.setItem(this.storageKeyValue, config)
    } 
    
    this.element.open = config[this.id]
  }
}
