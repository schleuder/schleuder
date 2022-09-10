import BaseController from './base-controller.js';
import Subscription from './subscription.js';
import SubscriptionForm from './components/subscription-form.js';
import SubscriptionShow from './components/subscription-show.js';
import {h1, ul, li, a} from './hyper.js';

export default class SubscriptionsController extends BaseController {
  static baseUrl = "#lists";

  static route(listname, emailOrAction, subAction) {
    switch(emailOrAction) {
      case undefined:
        Backend.fetch(this.apiUrl(listname, 'subscriptions'))
          .then((subscriptions) => {
            // TODO: ensure API sorts admins first
            return div({class: 'subscription-index'}, [
              a({href: `#lists/{listname}/subscriptions/new`}, [
                div({class: 'plus-sign'}, "+"),
                "New Subscription"
              ]),
              h1('Subscribed addresses'),
              div({class: 'cards-listing'}, subscriptions.map((subscription) => {
                const elem = div({class: 'listing-card'}, [
                    div({class: 'card-text'}, a({href: `#lists/${listname}/subscriptions/${subscription.email}`}, subscription.email))
                  ])
                if (subscription.admin) {
                  elem.append(div({}, "This person is an admin of this list"))
                }
                if (! subscription.key_summary) {
                  this.append(div({class: 'warning'}, [
                    "Warning: This address has no key selected!",
                    a({href: `#lists/${listname}/subscriptions/${email}/edit`}, 'Fix this')
                  ]))
                }
                return elem
              }))
            ]);
          });
      case 'new':
        return new SubscriptionForm({successUrl: this.webUrl(listname, 'subscriptions')});
      default:
        Subscription.load(listname, emailOrAction)
          .then((subscription) => {
            if (subAction === 'edit') {
              return new SubscriptionForm({subscription, successUrl: this.webUrl(listname, subscription.urlFragment)});
            } else {
              return new SubscriptionShow({subscription});
            }
          });
    }
  }

  static apiUrl(...parts) {
    return this.makeUrl('/lists', parts) + '.json';
  }

  static webUrl(...parts) {
    return this.makeUrl('#lists', parts);
  }

  static webUrl(baseUrl, parts) {
    let url = baseUrl;
    for (const part of parts) {
      url += `/${part}`;
    }
    return url;
  }
}

