import BaseComp from "./base-comp.js"
import Backend from "../backend.js"
import InputField from './input-field.js';
import KeyUpload from './key-upload.js';
import KeyUpload2 from './key-upload2.js';
import {h1, button, fieldset, legend, html} from "../hyper.js"

export default class SubscriptionForm extends BaseComp {
  constructor(listname, subscriptionEmail) {
    super(listname);
    this.class = 'subscription-edit';
    this.headline = h1();
    this.emailFieldset = fieldset(legend("Email"));
    this.keyFieldset = fieldset(legend("Key"));
    const submitBtn = button({type: "submit"}, "Save")
    submitBtn.addEventListener('submit', (ev) => {
      // TODO: invalidate url in elemCache
      // TODO: actually save data!
      ev.preventDefault();
      successCallback();
      window.location = successUrl;
    })
    this.append(this.headline, this.emailFieldset, this.keyFieldset, submitBtn);

    this.emailField = new InputField("email", "subscription-form-email", "Email", null, true)
    this.delivery = new InputField("checkbox", "subscription-form-delivery-enabled", "Delivery enabled?", "Receive the emails sent over the list?")
    this.admin = new InputField("checkbox", "subscription-form-admin", "Admin?", "May this person administer this list?")
    this.emailFieldset.append(this.emailField, this.delivery, this.admin)

    this.keyUpload = new KeyUpload2(listname)
    this.keyFieldset.append(this.keyUpload.render(true))

    if (! subscriptionEmail) {
      this.headline.textContent = "New subscription";
      this.keyUpload.finished.then(() => this.finished())
    } else {
      Backend.fetch(listname, "subscriptions", subscriptionEmail)
        .then((subscription) => {
          this.headline.textContent = `Edit ${subscription.email}`;
          this.emailField.value = subscription.email;
          this.delivery.checked = subscription.delivery_enabled;
          this.admin.checked = subscription.admin;

          this.keyUpload.finished
            .then(() => {
              this.keyFieldset.querySelector(`option[value="${subscription.fingerprint}"]`).selected = true;
            })
          this.finished()
        })
    }
  }
}

customElements.define('subscription-form', SubscriptionForm)
