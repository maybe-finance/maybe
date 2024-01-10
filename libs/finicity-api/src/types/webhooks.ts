import type { CustomerAccount } from './accounts'

/** https://docs.finicity.com/webhook-events-list/#webhooks-2-3 */
export type WebhookData =
    | {
          eventType: 'ping'
      }
    | {
          eventType: 'added' | 'discovered'
          payload: {
              accounts: CustomerAccount[]
              institutionId: string
          }
      }
    | {
          eventType: 'done'
          customerId: string
      }
    | {
          eventType: 'institutionNotFound'
          payload: {
              query: string
          }
      }
    | {
          eventType: 'institutionNotSupported'
          payload: {
              institutionId: string
          }
      }
    | {
          eventType: 'unableToConnect'
          payload: {
              institutionId: string
              code: number
          }
      }
