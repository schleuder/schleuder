import BaseController from './base-controller.js';
import Backend from './backend.js';
import Router from './router.js';
import './html-element.js';

export default class LoginController extends BaseController {
  static async show() {
    const elem = this.elem('#login');
    const submitBtn = elem.querySelector('#login button[type="submit"]');
    submitBtn.addEventListener('click', (ev) => {
      ev.preventDefault();
      this.authenticate(elem);
    });
    elem.show();
    return elem;
  }

  static async authenticate(elem) {
    const errorMessageElem = elem.querySelector('#login-error');
    const emailElem = elem.querySelector("#login #emailaddress");
    const pwElem = elem.querySelector("#login #password");
    errorMessageElem.hide();
    let email;
    let password;
    if (emailElem.reportValidity()) {
      email = emailElem.value;
    } else {
      return false;
    }
    if (pwElem.reportValidity()) {
      password = pwElem.value;
    } else {
      return false;
    }
    if (await Backend.checkCredentials(email, password)) {
      Router.route('lists');
    } else {
      errorMessageElem.show();
    }
  }
}
