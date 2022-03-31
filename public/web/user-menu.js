import Template from './template.js';
import BaseController from './base-controller.js';

export default class UserMenuController extends BaseController {
  static async show(emailaddress) {
    const el = this.elem('#user-menu');
    Template.fill(el.querySelector('#user-emailaddress'), {emailaddress: emailaddress});
    el.show();
    return el;
  }
}
