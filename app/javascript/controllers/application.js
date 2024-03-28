import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

Turbo.setConfirmMethod((message, element) => {
  let dialog = document.getElementById("turbo-confirm")
  let msg = JSON.parse(message)

  dialog.querySelector("[id='turbo-confirm-title']").innerHTML = msg.title;
  dialog.querySelector("[id='turbo-confirm-body']").innerHTML = msg.body;
  dialog.querySelector("[id='turbo-confirm-accept']").innerHTML = msg.accept;

  // prevent background from scrolling
  dialog.showModal()

  return new Promise((resolve, reject) => {
    dialog.addEventListener("close", () => {
        resolve(dialog.returnValue == "confirm")
    }, { once: true })
  })
})

export { application }
