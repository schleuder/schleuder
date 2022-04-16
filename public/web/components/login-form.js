import Backend from '../backend.js';
import Router from '../router.js';

export default class LoginForm extends HTMLFormElement {
  constructor() {
    super();
    this.emailElem = this.querySelector('#login-form-email');
    this.pwElem = this.querySelector('#login-form-password');
    this.errorMessageElem = this.querySelector('#login-form-error');
    this.addEventListener('submit', (ev) => {
      this.errorMessageElem.hide();
      ev.preventDefault();
      this.authenticate();
    })
  }

  async authenticate() {
    if (await Backend.checkCredentials(this.emailElem.value, this.pwElem.value)) {
      Router.route('lists');
      this.hide();
    } else {
      this.errorMessageElem.show();
    }
  }
}

customElements.define('login-form', LoginForm, {extends: 'form'});
