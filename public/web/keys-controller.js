import BaseController from './base-controller.js';

export default class KeysController extends BaseController {
  static async index(listname) {
    const instance = new this(listname);
    const keys = await instance.get(`keys.json`);
    for (const key of keys) {
      key['cssClass'] = key.subscription ? 'has-subscription' : ''
    }
    return instance.bakeFromTemplate('keysIndex', {listname: listname, keys: keys});
  }

  static async fresh(listname) {
    return this.bakeFromTemplate('keysFresh', {listname: listname});
  }

  static async show(listname, fingerprint) {
    const instance = new this(listname);
    const key = await instance.get(`keys/${fingerprint}.json?allDetails=true`);
    return instance.bakeFromTemplate('keysShow', {listname, ...key});
  }

  static async download(listname, fingerprint) {
    // TODO: Send ASCII-data to Browser and stay put.
  }
}
