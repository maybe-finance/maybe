Turbo.StreamActions.flash_message = function () {
  const container = document.getElementById('flash-messages');
  const template = container.querySelector('template');
  const element = template.content.cloneNode(true).querySelector('[data-controller=flash]');
  element.setAttribute('data-flash-message-value', this.getAttribute('message'));
  element.setAttribute('data-flash-type-value', this.getAttribute('type'));
  container.prepend(element);
}
