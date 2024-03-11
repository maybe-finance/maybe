import { Controller } from '@hotwired/stimulus';

export default class extends Controller {

  get cssInputSelector() {
    return 'input:not(.no-auto-submit), textarea:not(.no-auto-submit)';
  }

  get inputElements() {
    return this.element.querySelectorAll(this.cssInputSelector);
  }

  get selectElements() {
    return this.element.querySelectorAll('select:not(.no-auto-submit)');
  }

  connect() {
    [...this.inputElements, ...this.selectElements].forEach(el => el.addEventListener('change', this.handler));
  }

  disconnect() {
    [...this.inputElements, ...this.selectElements].forEach(el => el.removeEventListener('change', this.handler));
  }

  handler = (e) => {
    console.log(e);
    this.element.requestSubmit();
  }

}

