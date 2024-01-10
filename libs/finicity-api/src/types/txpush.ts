import type { CustomerAccount } from './accounts'
import type { Transaction } from './transactions'

export type TxPushSubscriptionRequest = {
    customerId: string | number
    accountId: string | number
    callbackUrl: string
}

type SubscriptionRecord = {
    id: number
    accountId: number
    type: 'account' | 'transaction'
    callbackUrl: string
    signingKey: string
}

export type TxPushSubscriptions = {
    subscriptions: SubscriptionRecord[]
}

export type TxPushEvent =
    | {
          class: 'transaction'
          type: 'created' | 'modified' | 'deleted'
          records: Transaction[]
      }
    | {
          class: 'account'
          type: 'modified' | 'deleted'
          records: CustomerAccount[]
      }

export type TxPushEventMessage = {
    event: TxPushEvent
}

export type TxPushDisableRequest = {
    customerId: string | number
    accountId: string | number
}
