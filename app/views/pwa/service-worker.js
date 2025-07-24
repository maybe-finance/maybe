// Add a service worker for processing Web Push notifications:
//
// self.addEventListener("push", async (event) => {
//   const { title, options } = await event.data.json()
//   event.waitUntil(self.registration.showNotification(title, options))
// })
// 
// self.addEventListener("notificationclick", function(event) {
//   event.notification.close()
//   event.waitUntil(
//     clients.matchAll({ type: "window" }).then((clientList) => {
//       for (let i = 0; i < clientList.length; i++) {
//         let client = clientList[i]
//         let clientPath = (new URL(client.url)).pathname
// 
//         if (clientPath == event.notification.data.path && "focus" in client) {
//           return client.focus()
//         }
//       }
// 
//       if (clients.openWindow) {
//         return clients.openWindow(event.notification.data.path)
//       }
//     })
//   )
// })


// _____--------_____
// Improve

self.addEventListener("push", async (event) => {
  if (!event.data) return

  try {
    const { title, options } = await event.data.json()
    if (!title || !options) return

    event.waitUntil(
      self.registration.showNotification(title, options)
    )
  } catch (error) {
    console.error(" Failed to Parse the Json:", error)
  }
})


self.addEventListener("notificationclick", (event) => {
  event.notification.close()

  const targetPath = event.notification?.data?.path
  if (!targetPath) return

  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        const clientPath = new URL(client.url).pathname

        if (clientPath === targetPath && "focus" in client) {
          return client.focus()
        }
      }

      // No matching tab found, open new one
      if (clients.openWindow) {
        return clients.openWindow(targetPath)
      }
    })
  )
})

