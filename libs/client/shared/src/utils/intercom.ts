export type IntercomData = {
    user_id?: string
    user_hash?: string
    email?: string
    name?: string

    last_request_at?: number

    'Manual Accounts'?: number
    'Connected Accounts'?: number
    Connections?: number
}

export function bootIntercom(data?: IntercomData) {
    const w = window as any
    w.Intercom('boot', {
        app_id: w.INTERCOM_APP_ID,
        ...data,
    })
}

export function updateIntercom(data?: IntercomData) {
    ;(window as any).Intercom('update', {
        ...data,
    })
}

export function trackIntercomEvent(name: string, data: Record<string, any>) {
    ;(window as any).Intercom('trackEvent', name, {
        ...data,
    })
}

export function showIntercom() {
    ;(window as any).Intercom('show')
}
