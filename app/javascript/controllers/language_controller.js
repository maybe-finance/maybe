import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ["auto"]

  change(event) {
    const selectedLanguage = event.target.value
    document.cookie = `locale=${selectedLanguage}; path=/`
    location.reload()
  }
}
