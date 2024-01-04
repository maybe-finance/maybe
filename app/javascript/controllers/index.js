// Import and register all your controllers from the importmap under controllers/*

import { application } from "controllers/application"

// Eager load all controllers defined in the import map under controllers/**/*_controller
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

// Lazy load controllers as they appear in the DOM (remember not to preload controllers in import map!)
// import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
// lazyLoadControllersFrom("controllers", application)

import Clipboard from 'stimulus-clipboard'
application.register('clipboard', Clipboard)

import Timeago from 'stimulus-timeago'
application.register('timeago', Timeago)

import { Turbo } from "@hotwired/turbo-rails"
window.Turbo = Turbo

import { AddressLookup } from "@addresszen/address-lookup";
document.addEventListener("turbo:load", () => {
  const inputField = document.getElementById("full_address");

  if (inputField) {
    AddressLookup.setup({
      apiKey: "ak_lgpf8sd217tzr1llewdg3ucAEVMaT",
      removeOrganisation: true,
      inputField: "#full_address",
      onAddressRetrieved: (address) => {
        const result = [
          address.line_1,
          address.line_2,
          address.city,
          address.state,
          address.zip_plus_4_code
        ]
          .filter((elem) => elem !== "")
          .join(", ");
        document.getElementById("full_address").value = result;
        document.getElementById("dataset").value = JSON.stringify(address);
        document.getElementById("name").value = address.line_1;
      }
    });
  }
});