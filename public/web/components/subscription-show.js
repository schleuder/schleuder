import BaseComp from "./base-comp.js"
import Backend from "../backend.js"
import { h1, p, span, icon, a } from '../hyper.js';

export default class SubscriptionShow extends BaseComp {
  constructor(listname, email) {
    super(listname, "subscriptions");
    this.append(
      a({class: "action-link", href: this.urlFor("subscriptions", email, "edit")}, [icon("edit", {class: "small-icon"}), "edit"]),
      h1(email)
    )
    Backend.fetch(listname, "subscriptions", email)
      .then((subscription) => {
        if (subscription.admin) {
          this.appendPara(icon("heart"), "This person is an admin of this list");
        }
        if (subscription.delivery_enabled) {
          this.appendPara(icon("delivery"), "Email-delivery is enabled.")
        } else {
          this.appendPara(icon("delivery-disabled"), "Email-delivery is disabled.")
        }
        if (subscription.fingerprint) {
          this.appendPara(
            icon("key-outlined"),
            "Selected key: ",
            a({href: this.urlFor("keys", subscription.fingerprint)}, subscription.key_summary)
          )
        } else {
          this.appendPara(
            icon("key-missing"),
            span({class: "warning"}, "No key is selected!"),
            a({href: this.urlFor("subscriptions", subscription.email, "edit#keyselection")}, icon("edit"), "Fix this")
          )
        }
        this.finished()
      })
  }

  appendPara(...content) {
    this.append(p({class: "attribute"}, ...content));
  }
}

customElements.define('subscription-show', SubscriptionShow)
