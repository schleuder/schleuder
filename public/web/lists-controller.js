import BaseController from './base-controller.js';
import Template from './template.js';
import Backend from './backend.js';

export default class ListsController extends BaseController {
  static async index() {
    // TODO: Extend API to provide more details
    const listEmails = await Backend.fetch('/lists.json');
    const lists = listEmails.map((email) => { return {email} });
    return Template.bake('lists', {lists});
  }

  static async edit(listname) {
    const list = await Backend.fetch(`/lists/${listname}.json`);
    return Template.bake('listEdit', {list});
  }
}
