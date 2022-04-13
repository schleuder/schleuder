import BaseController from './base-controller.js';

export default class Subscriptions extends BaseController {
  static async index(listname) {
    const instance = new this(listname);
    const subscriptions = await instance.get('subscriptions.json');
    // Sort admins first
    subscriptions.sort((a, b) => {
      if (a.admin && ! b.admin) {
        // Put a before b
        return -1;
      } else if (! a.admin && b.admin) {
        // Put b before a
        return 1;
      } else {
        // Don't change
        return 0;
      }
    });
    return instance.bakeFromTemplate('subscriptions', {listname, subscriptions});
  }

  static async fresh(listname) {
  }

  static async edit(listname, email) {
  }

  static async show(listname, email) {
    const instance = new this(listname);
    const subscription = await instance.get(`subscriptions/${email}.json`);
    return instance.bakeFromTemplate('subscription', {
      listname: listname,
      email: subscription.email,
      adminYesNo: subscription.admin ? "Yes" : "No"
    });
  }
}

