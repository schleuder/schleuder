import BaseComp from "./base-comp.js"
import Backend from "../backend.js"
import ActionLink from "./action-link.js"
import IndexCard from './index-card.js'
import CardPopup from './card-popup.js'
import {h1, div} from '../hyper.js'

export default class SubscriptionIndex extends BaseComp {
  constructor(listname) {
    super(listname)
    this.append(
      new ActionLink(this.urlFor(["subscriptions", "new"]), "New Subscription", div({class: 'plus-sign'}, "+")),
      h1('Subscribed addresses')
    )
    Backend.fetch(listname, "subscriptions") 
      .then((subscriptions) => {
        const cards = subscriptions.map((subscription) => {
          const card = new IndexCard('person', this.linkTo(subscription.email, ["subscriptions", subscription.email]))
          if (subscription.admin) {
            card.append(new CardPopup('heart', "This person is an admin of this list"))
          }
          if (! subscription.fingerprint) {
            card.append(new CardPopup('key-missing', div({class: 'warning'}, [
                  "Warning: This address has no key selected!",
                  this.linkTo('Fix this', ["subscriptions", subscription.email, "edit"])
                ])))
          }
          return card
        })
        this.append(div({class: 'index-cards'}, cards))
        this.finished()
      })
  }

}

customElements.define('subscription-index', SubscriptionIndex)
