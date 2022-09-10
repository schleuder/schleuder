import { label, abbr, small, html } from './hyper.js';

export default class SelectField extends HTMLElement {
  constructor(name, labelText, usageText, required, options, selectedValue=null) {
    super()
    required = !! required;

    const labelEl = label({for: name}, labelText)
    if (required) {
      labelEl.append(abbr({class: "required-hint", title: "This field is required"}, '*'))
    }
    this.append(labelEl)

    this.append(html("select", {id: name}, Object.entries(options).map(([value, text]) => {
      return html("option", {value: value, ...(value === selectedValue && {selected: true})}, text)
    })))

    if (usageText) {
      this.append(small({class: 'usage'}, usageText))
    }
  }
}

customElements.define("select-field", SelectField)
