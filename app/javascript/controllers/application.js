import { Application } from "@hotwired/stimulus";

const application = Application.start();

// Configure Stimulus development experience
application.debug = false;
window.Stimulus = application;

Turbo.config.forms.confirm = (message) => {
  const dialog = document.getElementById("turbo-confirm");

  try {
    const { title, body, accept, acceptClass } = JSON.parse(message);

    if (title) {
      document.getElementById("turbo-confirm-title").innerHTML = title;
    }

    if (body) {
      document.getElementById("turbo-confirm-body").innerHTML = body;
    }

    if (accept) {
      document.getElementById("turbo-confirm-accept").innerHTML = accept;
    }

    if (acceptClass) {
      document.getElementById("turbo-confirm-accept").className = acceptClass;
    }
  } catch (e) {
    document.getElementById("turbo-confirm-title").innerText = message;
  }

  dialog.showModal();

  return new Promise((resolve) => {
    dialog.addEventListener(
      "close",
      () => {
        const confirmed = dialog.returnValue === "confirm";

        if (!confirmed) {
          document.getElementById("turbo-confirm-title").innerHTML =
            "Are you sure?";
          document.getElementById("turbo-confirm-body").innerHTML =
            "You will not be able to undo this decision";
          document.getElementById("turbo-confirm-accept").innerHTML = "Confirm";
        }

        resolve(confirmed);
      },
      { once: true },
    );
  });
};

export { application };
