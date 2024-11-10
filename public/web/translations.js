const translations = {
  en: {
    person_is_list_admin: "This person is an admin of this list",
    new_subscription: "New Subscription",
    subscribed_addresses: "Subscribed addresses",
    warning_no_key: "Warning: This address has no key selected!",
    fix_this: "Fix this",
    upload_key: "Upload key",
    used_by: "Used by ",
    your_lists: "Your lists",
    error_could_not_connect_to_server: "Could not connect to server, please check your network connection or try again later!",
    error_unexpected_problem: "An unexpected problem occurred, please try again later",
    keys_known_to_list: "Keys known to %1",
    subscriptions: "Subscriptions",
    keys: "Keys",
    list_options: "List options",
    my_lists: "My lists",
  },
  de: {
    person_is_list_admin: "Diese Person verwaltet diese Liste",
    new_subscription: "Neuer Eintrag",
    subscribed_addresses: "Eingetragene Adressen",
    warning_no_key: "Achtung: Zu dieser Adresse wurde kein Schlüssel ausgewählt!",
    fix_this: "Ändern",
    upload_key: "Schlüssel hochladen",
    used_by: "Verwendet von ",
    your_lists: "Deine Listen",
    error_could_not_connect_to_server: "Der Server ist nicht erreichbar, bitte prüfe deine Internetverbindung und versuche es später nochmal!",
    error_unexpected_problem: "Es ist ein unerwartetes Problem aufgetreten, bitte versuche es später nochmal",
    keys_known_to_list: "Schlüssel für %1",
    subscriptions: "Eingetragene Adressen",
    keys: "Schlüssel",
    list_options: "Listen-Einstellungen",
    my_lists: "Meine Listen",
  }
}

const getLangFromBrowser = () => {
  if (navigator.languages) {
    navigator.languages.forEach((locale) => {
      const l = locale.split(/[-_]/)[0];
      if (translations[l] !== undefined) {
        return l;
      }
    })
  }
}

const getLangFromURL = () => {
  if (location.search.length > 0) {
    const params = new URLSearchParams(location.search)
    return params.get("lang");
  }
}

window.language = getLangFromURL() || getLangFromBrowser() || "en";

export const t = (key, ...args) => {
  let string = translations[window.language][key];
  if (string === undefined) {
    throw new Error(`Missing translation string for key '${key}'!`);
    return key;
  }
  // Replace %1, %2, etc. in strings. If `args` is empty, this does nothing.
  args.forEach((arg, index) => string = string.replace(`%${index+1}`, arg))
  return string;
}

