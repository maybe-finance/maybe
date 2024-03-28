import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

Turbo.setConfirmMethod((message, element) => {
  let dialog = document.getElementById("turbo-confirm")
  let msg;

  try {
    msg = JSON.parse(message)
  } catch (e) {
    msg = {
      title: "Are you sure?",
      body: "You will not be able to undo this decision",
      accept: "Confirm"
    }
  }

  dialog.querySelector("[id='turbo-confirm-title']").innerHTML = msg.title ? msg.title : "Are you sure?";
  dialog.querySelector("[id='turbo-confirm-body']").innerHTML = msg.body ? msg.body : "You will not be able to undo this decision";
  dialog.querySelector("[id='turbo-confirm-accept']").innerHTML = msg.accept ? msg.accept : "Confirm";

  dialog.showModal()

  return new Promise((resolve, reject) => {
    dialog.addEventListener("close", () => {
        resolve(dialog.returnValue == "confirm")
    }, { once: true })
  })
})

export { application }
