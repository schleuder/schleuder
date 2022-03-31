export default class FieldSet extends HTMLFieldSetElement {
  constructor(text) {
    super();
    const legend = document.createElement('legend');
    legend.textContent = text;
    this.append(legend);
  }
}

customElements.define('field-set', FieldSet, {extends: 'fieldset'});
