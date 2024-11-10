import BaseComp from "./base-comp.js";
import Backend from "../backend.js";
import { a, div, h1, card, cardPopup, actionNewLink } from "../hyper.js";
import {t} from '../translations.js'

export default class KeyIndex extends BaseComp {
  constructor(listname) {
    super(listname);
    this.append(
      actionNewLink(this.urlFor(["keys", "new"]), "upload_key"),
      h1(t("keys_known_to_list", listname)),
    );
    Backend.fetch(listname, "keys")
      .then((keys) => {
        const cards = keys.map((key) => {
          const theCard = card("key", a({href: this.urlFor("keys", key.fingerprint)}, key.key_summary))
          if (key.subscription) {
            theCard.append(
              cardPopup(
                "person",
                div([
                  t("used_by"), 
                  a({href: this.urlFor("subscriptions", key.subscription)}, key.subscription,)
                ]),
              ),
            );
          }
          return theCard;
        });
        this.append(div({ class: "index-cards" }, cards));
        this.finished();
      });
  }
}

customElements.define("key-index", KeyIndex);
