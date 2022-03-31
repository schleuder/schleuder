import EmailField from './email-field.js';
import CheckboxField from './checkbox-field.js';
import FieldSet from './field-set.js';
import SubmitButton from './submit-button.js';
import { makeElem } from '../helper.js';

export default class SubscriptionEdit extends HTMLDivElement {
  constructor(subscription) {
    super();
    this.class = 'subscription-edit';
    this.headline = makeElem('h1');
    this.emailFieldset = new FieldSet('Email')
    this.keyFieldset = new FieldSet('Key')
    const submitBtn = new SubmitButton({text: 'Save'});
    this.append(this.headline, this.emailFieldset, this.keyFieldset, submitBtn);

    this.emailField = new EmailField({name: "subscription-form-email", label: "Email", required: true})
    this.delivery = new CheckboxField({name: "subscription-form-delivery-enabled", label: "Delivery enabled?", usage: "Receive the emails sent over the list?"});
    this.admin = new CheckboxField({name: "subscription-form-admin", label: "Admin?", usage: "May this person administer this list?"});


    console.info({subscription})
    if (subscription) {
      this.emailField.value = subscription.email;
      this.delivery.checked = subscription.delivery_enabled;
      this.admin.checked = subscription.admin;
      this.headline.textContent = `Edit ${this.email}`;
    } else {
      this.headline.textContent = "New subscription";
    }
    this.emailFieldset.append(this.emailField, this.delivery, this.admin);
  }
}

customElements.define('subscription-edit', SubscriptionEdit, {extends: 'div'});
