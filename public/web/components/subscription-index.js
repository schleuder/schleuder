import BaseComp from "./base-comp.js"
import Backend from "../backend.js"
import {a, h1, div, card, cardPopup, actionNewLink} from '../hyper.js'
import {t} from '../translations.js'

export default class SubscriptionIndex extends BaseComp {
  constructor(listname) {
    super(listname)
    this.append(
      actionNewLink(this.urlFor(["subscriptions", "new"]), "new_subscription"),
      h1(t('subscribed_addresses'))
    )
    Backend.fetch(listname, "subscriptions") 
      .then((subscriptions) => {
        const cards = subscriptions.map((subscription) => {
          const theCard = card('person', a({href: this.urlFor("subscriptions", subscription.email)}, subscription.email))
          if (subscription.admin) {
            theCard.append(cardPopup('heart', t("person_is_list_admin")))
          }
          if (! subscription.fingerprint) {
            theCard.append(cardPopup('key-missing', div({class: 'warning'}, [
                  t("warning_no_key"),
                  a({href: this.urlFor("subscriptions", subscription.email, "edit")}, t("fix_this"))
                ])))
          }
          return theCard
        })
        this.append(div({class: 'index-cards'}, cards))
        this.finished()
      })
  }

}

customElements.define('subscription-index', SubscriptionIndex)
