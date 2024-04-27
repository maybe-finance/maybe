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
      const button = document.createElement("button")
      button.setAttribute("id", "turbo-confirm-reject")
      button.setAttribute("class", "w-full text-red-600 rounded-xl text-center p-[10px] border mt-2")
      button.setAttribute("value", "reject")
      button.innerHTML = reject

      document.getElementById("turbo-confirm-dialog-form").appendChild(button)
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
