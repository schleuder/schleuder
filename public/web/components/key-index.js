import BaseComp from "./base-comp.js";
import Backend from "../backend.js";
import ActionLink from "./action-link.js";
import IndexCard from "./index-card.js";
import CardPopup from "./card-popup.js";
import { div, h1, svgObject } from "../hyper.js";

export default class KeyIndex extends BaseComp {
  constructor(listname) {
    super(listname);
    this.append(
      new ActionLink(this.urlFor(["keys", "new"]), [
        svgObject("plus", "+"),
        "Upload key",
      ]),
      h1(`Keys known to ${listname}`),
    );
    Backend.fetch(listname, "keys")
      .then((keys) => {
        const cards = keys.map((key) => {
          const card = new IndexCard(
            "key",
            this.linkTo(key.key_summary, ["keys", key.fingerprint]),
          );
          if (key.subscription) {
            card.append(
              new CardPopup(
                "person",
                div([
                  "Used by ",
                  this.linkTo(key.subscription, [
                    "subscriptions",
                    key.subscription,
                  ]),
                ]),
              ),
            );
          }
          return card;
        });
        this.append(div({ class: "index-cards" }, cards));
        this.finished();
      });
  }
}

customElements.define("key-index", KeyIndex);
