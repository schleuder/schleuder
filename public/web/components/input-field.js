import { label, abbr, small, input } from '../hyper.js';

export default class InputField extends HTMLElement {
  inputEl;

  constructor(type, name, labelText, usageText, required) {
    super();
    this.className = `type-${type}`;
    required = !! required;

    const labelEl = label({for: name}, labelText)
    if (required) {
      labelEl.appendChild(abbr({class: "required-hint", title: "This field is required"}, '*'))
    }

    this.inputEl = input({type: type, id: name, required: required})

    if (type === "checkbox") {
      this.append(this.inputEl, labelEl)
    } else {
      this.append(labelEl, this.inputEl)
    }


    if (usageText) {
      this.append(small({class: 'usage'}, usageText))
    }
  }

  set value(val) {
    this.inputEl.value = val
  }

  get value() {
    return this.inputEl.value
  }

  set checked(val) {
    this.inputEl.checked = val
  }

  get checked() {
    return this.inputEl.checked
  }

}

customElements.define('input-field', InputField);
