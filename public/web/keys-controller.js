import BaseController from './base-controller.js';
import Template from './template.js';
import Backend from './backend.js';
import './html-element.js';

export default class KeysController extends BaseController {
  static async index(listname) {
    const keys = await Backend.fetch(`/lists/${listname}/keys.json`);
    return Template.bake('keysIndex', {listname: listname, keys: keys});
  }

  static async fresh(listname) {
    return Template.bake('keysFresh', {listname: listname});
  }

  static async show(listname, fingerprint) {
    const key = await Backend.fetch(`/lists/${listname}/keys/${fingerprint}.json?allDetails=true`);
    return Template.bake('keysShow', {listname, ...key});
  }

  static async download(listname, fingerprint) {
    // TODO: Send ASCII-data to Browser and stay put.
  }
}
