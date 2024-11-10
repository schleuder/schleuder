import {t} from "./translations.js"

export const html = (type, ...args) => {
    args = args.flat()
    let content
    let attributes
    const elem = document.createElement(type)
    if (args[0]?.constructor?.name === 'Object') {
      attributes = args.shift()
      for (const [key, value] of Object.entries(attributes)) {
        if (key.slice(0, 2) === "on" && typeof(value) === "function") {
          const eventName = key.slice(2).toLowerCase();
          elem.addEventListener(eventName, value);
        } else {
          elem.setAttribute(key, value)
        }
      }
    }
    content = args
    if (content?.constructor?.name !== 'Array') {
      content = [content]
    }
    for (const thing of content) {
      if (thing) {
        if (typeof(thing) === 'string') {
          elem.append(document.createTextNode(thing))
        } else if (thing.nodeName) {
          elem.append(thing)
        }
      }
    }
    return elem
  }

// exports must be defined statically, can't metaprogram without tricks or destructuring on the importing side.
export const h1 = (...args) => html('h1', ...args)
export const h2 = (...args) => html('h2', ...args)
export const h3 = (...args) => html('h3', ...args)
export const div = (...args) => html('div', ...args)
export const span = (...args) => html('span', ...args)
export const p = (...args) => html('p', ...args)
export const a = (...args) => html('a', ...args)
export const ul = (...args) => html('ul', ...args)
export const li = (...args) => html('li', ...args)
export const img = (...args) => html('img', ...args)
export const object = (...args) => html('object', ...args)
export const label = (...args) => html('label', ...args)
export const input = (...args) => html('input', ...args)
export const button = (...args) => html('button', ...args)
export const fieldset = (...args) => html('fieldset', ...args)
export const legend = (...args) => html('legend', ...args)
export const abbr = (...args) => html('abbr', ...args)
export const small = (...args) => html('small', ...args)
export const textarea = (...args) => html('textarea', ...args)

export const keyUploadFile = () => html('div', {class: "key-upload-file"}, html("label", "Upload a new key file", html("input", {id: "key-upload-file", type: "file"})))
export const keyUploadText = () => html('div', {class: "key-upload-text"}, html("label", "Paste a new key as text", html("textarea", {id: "key-upload-text"})))
export const keyUploadSpacer = () => html('div', {class: "key-upload-spacer"}, "or", html("div", {class: "precedence"}, "↑ precedence"))

export const icon = (name, attribs) => html('img', {src: `./images/${name}.svg`, alt: `Icon showing ${name}`, ...attribs})
export const svgObject = (name, content) => object({type: "image/svg+xml", data: `./images/${name}.svg`}, content);
export const actionNewLink = (url, tr_key) => a({class: 'action-link', href: url}, [svgObject("plus", "+"), t(tr_key)])

export const card = (iconName, content) => div({class: 'card'}, icon(iconName), div({class: 'card-text'}, content))
export const cardPopup = (iconName, content) => div({class: 'card-popup'}, icon(iconName), div({class: `card-popup-text`}, content))
