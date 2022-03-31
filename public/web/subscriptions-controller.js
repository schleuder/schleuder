import BaseController from './base-controller.js';
import Template from './template.js';
import Backend from './backend.js';

export default class Subscriptions extends BaseController {
  static async index(listname) {
    const subscriptions = await Backend.fetch(`/lists/${listname}/subscriptions.json`);
    subscriptions.forEach((subscription) => { subscription.adminCssClass = subscription.admin?  "admin" : ""});
    return Template.bake('subscriptions', {listname, subscriptions});
  }

  static async show(listname, email) {
    const subscription = await Backend.fetch(`/lists/${listname}/subscriptions/${email}.json`);
    return Template.bake('subscription', {
      listname: listname,
      email: subscription.email,
      adminYesNo: subscription.admin ? "Yes" : "No"
    });
  }
}

