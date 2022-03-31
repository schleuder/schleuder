import './html-element.js';

export default class Template {

  /** @type HTMLElement */
  elem;

  /**
   * @param {Node} node - HTML template node
   */
  constructor(node) {
    if (! (node instanceof Node)) {
      throw new Error("Need HTML Node as input");
    }
    if (node.content.children.length > 1) {
      throw new Error("Each template node needs exactly one 'root' element");
    }
    this.elem = node.content.firstElementChild.cloneNode(true);
  }

  /**
   * @param {string} id - ID attribute of HTML template node
   */
  static fromId(id) {
    const node = document.getElementById(id);
    if (!node) {
      throw new Error(`No element found with ID '${id}'`);
    }
    return new this(node);
  }
  
  /**
   * @param {Object} replacements - Key-value object containing variable replacements
   */
  render(replacements) {
    replacements = replacements || {}
    return this.parse(this.elem, replacements); /** @type HTMLElement */
  }

  /**
   * @param {Node} node - HTML node
   * @param {Object} replacements - Key-value object containing variable replacements
   */
  parse(node, replacements) {
    // if-clauses
    if (node.dataset.if) {
      const replacement = replacements[node.dataset.if];
      if (this.isAbsent(replacement)) {
        node.remove();
        return;
      }
    }

    if (node.dataset.ifNot) {
      const replacement = replacements[node.dataset.ifNot];
      if (! this.isAbsent(replacement)) {
        node.remove();
        return;
      }
    }

    // Sub-templates
    if (node.nodeName === 'TEMPLATE') {
      const foreach = node.dataset.foreach;
      if (foreach && replacements[foreach] instanceof Array) {
        replacements[foreach].forEach((item) => {
          // Add the attributes of `item` last so they can overwrite the
          // previous ones in case of naming collisions.
          const elem = new this.constructor(node).render({...replacements, ...item});
          // insertAdjacentElement() has curious effects (some parts get rendered twice, other not), thus we avoid it.
          node.parentElement.appendChild(elem);
        });
        return node;
      }
    }

    // Text or child nodes
    node.childNodes.forEach((childNode) => {
      // Text
      if (childNode.nodeType === Node.TEXT_NODE) {
        this.handleNodeValue(childNode, replacements);
      } else {
        // Recurse into child nodes
        this.parse(childNode, replacements);
      }
    });

    // Attributes of this node
    if (node.attributes) {
      for (const attr of node.attributes) {
        this.handleNodeValue(attr, replacements);
      }
    }

    return node;
  }

  /**
   * @param {Node} node - HTML node
   * @param {Object} replacements - Key-value object containing variable replacements
   */
  handleNodeValue(node, replacements) {
    // nodeValue can be `null` for some kind of elements.
    if (! node.nodeValue || ! node.nodeValue.includes('{')) {
      return;
    }
    const newValue = node.nodeValue.replace(/{(\S+?)}/g, (_, word) => {
      if (typeof(replacements[word]) !== 'undefined') {
        return replacements[word];
      } else {
        console.error(`Template replacement variable '${word}' is undefined in replacements`);
        return "";
      }
    });
    node.nodeValue = newValue;
  }

  isAbsent(arg) {
    // Object.keys() works for `false`, strings and arrays, too.
    return (typeof(arg) === 'undefined' || arg === null || arg === false || (arg !== true && Object.keys(arg).length === 0));
  }
}
