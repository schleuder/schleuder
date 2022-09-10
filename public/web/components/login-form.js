import Backend from '../backend.js';
import InputField from './input-field.js';
import NotiFier from "../noti-fier.js"
import {button} from "../hyper.js"

export default class LoginForm extends HTMLFormElement {
  constructor() {
    super();
    this.emailField = new InputField("email", "login-form-email", "Email", null, true)
    this.passwordField = new InputField("password", "login-form-password", "Password", null, true)
    
    this.append(this.emailField, this.passwordField, button({type: "submit"}, 'Login'));
    this.addEventListener('submit', (ev) => {
      ev.preventDefault()
      NotiFier.clearAll()
      this.authenticate()
    })
  }

  async authenticate() {
    if (await Backend.checkCredentials(this.emailField.value, this.passwordField.value)) {
      this.hide();
      window.location = '#lists'
    } else {
      NotiFier.error('Login failed, please check your input!')
    }
  }
}

customElements.define('login-form', LoginForm, {extends: 'form'});
