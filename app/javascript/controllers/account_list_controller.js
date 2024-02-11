import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="account-list"
export default class extends Controller {

  updateDetailState() {
    const accountType = this.element.dataset.accountType
    const config = JSON.parse(localStorage.getItem('accountList'))

    config[accountType] = !config[accountType]
    localStorage.setItem('accountList', JSON.stringify(config))
  }

  connect() {
    const detailsElement = this.element
    const accountType = this.element.dataset.accountType
    let config = JSON.parse(localStorage.getItem('accountList'))

    if(!config) {
      config = {}
      localStorage.setItem('accountList', JSON.stringify(config))
    } 
    
    if (!config[accountType]) {
      config[accountType] = detailsElement.open
      localStorage.setItem('accountList', JSON.stringify(config))
    } 
    
    detailsElement.open = config[accountType]
  }
} 