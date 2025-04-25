import { Application } from "@hotwired/stimulus";

const application = Application.start();

// Configure Stimulus development experience
application.debug = false;
window.Stimulus = application;

Turbo.config.forms.confirm = (data) => {
  const confirmDialogController =
    application.getControllerForElementAndIdentifier(
      document.getElementById("confirm-dialog"),
      "confirm-dialog",
    );

  return confirmDialogController.handleConfirm(data);
};

export { application };
