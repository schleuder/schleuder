import BaseComponent from "./base-component.js";

export default class PasswordInput extends BaseComponent {
  type = 'password';
  
  connectedCallback() {
    this.mount(this.makeLabel(), this.makeInput());
  }
}

customElements.define('password-input', PasswordInput);
