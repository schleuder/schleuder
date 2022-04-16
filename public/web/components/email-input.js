import BaseComponent from "./base-component.js";

export default class EmailInput extends BaseComponent {
  type = 'email';

  connectedCallback() {
    this.mount(this.makeLabel(), this.makeInput({value: this.getAttribute('email')}));
  }
}

customElements.define('email-input', EmailInput);
