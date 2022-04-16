import BaseComponent from "./base-component.js";

export default class CheckBox extends BaseComponent {
  type = 'checkbox';

  connectedCallback() {
    this.mount(this.makeInput({checked: this.getAttribute('checked')}), this.makeLabel(), this.makeUsage());
  }
}

customElements.define('check-box', CheckBox);
