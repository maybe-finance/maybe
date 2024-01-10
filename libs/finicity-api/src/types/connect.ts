/** https://api-reference.finicity.com/#/rest/models/structures/generate-connect-url-request-lite-v2 */
export type GenerateLiteConnectUrlRequest = {
    partnerId: string
    customerId: string
    institutionId: string
    redirectUri?: string
    webhook?: string
    webhookContentType?: string
    webhookData?: object
    webhookHeaders?: object
    experience?: string
    singleUseUrl?: boolean
}

/** https://api-reference.finicity.com/#/rest/models/structures/generate-connect-url-request-fix-v2 */
export type GenerateFixConnectUrlRequest = {
    partnerId: string
    customerId: string
    institutionLoginId: string | number
    redirectUri?: string
    webhook?: string
    webhookContentType?: string
    webhookData?: object
    webhookHeaders?: object
    experience?: string
    singleUseUrl?: boolean
}

/** https://api-reference.finicity.com/#/rest/models/structures/generate-connect-url-response */
export type GenerateConnectUrlResponse = {
    link: string
}
