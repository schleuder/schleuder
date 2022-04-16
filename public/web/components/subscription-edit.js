import Backend from '../backend.js';
import EmailInput from './email-input.js';

export default class SubscriptionEdit extends HTMLElement {
  constructor(listname, email) {
    super();
    console.info('constructor subEdit')
    this.listname = listname;
    this.email = email;
    this.wrapper = this.makeElem('div', {class: this.nodeName.toLocaleLowerCase()});
    this.delivery = this.makeElem('check-box', {name: "subscription-form-delivery-enabled", label: "Delivery enabled?", usage: "Receive the emails sent over the list?"});
    this.admin = this.makeElem('check-box', {name: "subscription-form-admin", label: "Admin?", usage: "May this person administer this list?"});
    if (this.listname && this.email) {
      Backend.fetch(`/lists/${this.listname}/subscriptions/${this.email}.json`)
        .then((subscription) => {
          this.emailInput = new EmailInput({label: "Email", name: "subscription-form-email", required: true, email: subscription.email})
          this.delivery.setAttribute('checked', subscription.delivery_enabled);
          this.admin.setAttribute('checked', subscription.admin);
          this.wrapper.append(this.emailInput, this.delivery, this.admin);
          this.insertAdjacentElement('beforebegin', this.wrapper);
        })
    } else {
      this.wrapper.append(this.emailInput, this.delivery, this.admin);
      this.insertAdjacentElement('beforebegin', this.wrapper);
    }
  }

  async connectedCallback() {
    console.info('connectedCallback subEdit')
  }  

  makeElem(kind, attributes, textContent) {
    const elem = document.createElement(kind);
    if (attributes) {
      for (const key of Object.keys(attributes)) {
        elem.setAttribute(key, attributes[key]);
      }
    }
    if (textContent) {
      elem.textContent = textContent;
    }
    return elem;
  }
}

customElements.define('subscription-edit', SubscriptionEdit);
