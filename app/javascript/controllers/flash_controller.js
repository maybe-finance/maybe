import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['noticeIcon', 'alertIcon', 'message']
  static values = { type: String, message: String }

  connect = () => {
    setTimeout(() => this.dismiss(), 5000);
    this.messageTarget.innerHTML = this.messageValue;
    this[`${this.typeValue}IconTarget`].classList.remove('hidden');
  }

  dismiss = () => {
    this.element.classList.add('opacity-0', 'translate-x-4');
    this.element.ontransitionend = () => this.element.remove();
  }

}
