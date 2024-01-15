// https://teller.io/docs/api/webhooks

export type WebhookData = {
    id: string
    payload: {
        enrollment_id: string
        reason: string
    }
    timestamp: string
    type: string
}
