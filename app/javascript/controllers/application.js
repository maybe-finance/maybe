import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

Turbo.setConfirmMethod((message) => {
  const dialog = document.getElementById("turbo-confirm");

  try {
    const { title, body, accept, reject, acceptClass } = JSON.parse(message);

    if (title) {
      document.getElementById("turbo-confirm-title").innerHTML = title;
    }

    if (body) {
      document.getElementById("turbo-confirm-body").innerHTML = body;
    }

    if (acceptClass) {
      document.getElementById("turbo-confirm-accept").className += acceptClass
    }

    if (accept) {
      document.getElementById("turbo-confirm-accept").innerHTML = accept;
    }

    if (reject) {
      document.getElementById("turbo-confirm-reject").innerHTML = reject;
    } else {
      document.getElementById("turbo-confirm-reject").remove()
    }

  } catch (e) {
    document.getElementById("turbo-confirm-title").innerText = message;
  }

  dialog.showModal();

  return new Promise((resolve) => {
    dialog.addEventListener("close", () => {
        resolve(dialog.returnValue == "confirm")
    }, { once: true })
  })
})

export { application }
