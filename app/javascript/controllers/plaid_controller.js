import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="plaid"
export default class extends Controller {
  static values = {
    linkToken: String,
  };

  open() {
    const handler = Plaid.create({
      token: this.linkTokenValue,
      onSuccess: this.handleSuccess,
      onLoad: this.handleLoad,
      onExit: this.handleExit,
      onEvent: this.handleEvent,
    });

    handler.open();
  }

  handleSuccess(public_token, metadata) {
    fetch("/plaid_items", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
      },
      body: JSON.stringify({
        plaid_item: {
          public_token: public_token,
          metadata: metadata,
        },
      }),
    }).then((response) => {
      if (response.redirected) {
        window.location.href = response.url;
      }
    });
  }

  handleExit(err, metadata) {
    // no-op
  }

  handleEvent(eventName, metadata) {
    // no-op
  }

  handleLoad() {
    // no-op
  }
}
