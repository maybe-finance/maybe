import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="plaid"
export default class extends Controller {
  static values = {
    linkToken: String,
    region: { type: String, default: "us" },
    isUpdate: { type: Boolean, default: false },
    itemId: String,
  };

  connect() {
    this.open();
  }

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

  handleSuccess = (public_token, metadata) => {
    if (this.isUpdateValue) {
      // Trigger a sync to verify the connection and update status
      fetch(`/plaid_items/${this.itemIdValue}/sync`, {
        method: "POST",
        headers: {
          Accept: "application/json",
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
        },
      }).then(() => {
        // Refresh the page to show the updated status
        window.location.href = "/accounts";
      });
      return;
    }

    // For new connections, create a new Plaid item
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
          region: this.regionValue,
        },
      }),
    }).then((response) => {
      if (response.redirected) {
        window.location.href = response.url;
      }
    });
  };

  handleExit = (err, metadata) => {
    // If there was an error during update mode, refresh the page to show latest status
    if (err && metadata.status === "requires_credentials") {
      window.location.href = "/accounts";
    }
  };

  handleEvent = (eventName, metadata) => {
    // no-op
  };

  handleLoad = () => {
    // no-op
  };
}
