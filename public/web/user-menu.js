import Template from './template.js';
import BaseController from './base-controller.js';

export default class UserMenuController extends BaseController {
  static async show(emailaddress) {
    const el = Template.fromId('user-menu').render({emailaddress: emailaddress});
    document.querySelector('#header').appendChild(el);
    return el;
  }
}
