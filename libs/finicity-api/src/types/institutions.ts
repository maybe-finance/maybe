/** https://api-reference.finicity.com/#/rest/models/structures/institution-address */
export type InstitutionAddress = {
    city?: string
    state?: string
    country?: string
    postalCode?: string
    addressLine1?: string
    addressLine2?: string
}

/** https://api-reference.finicity.com/#/rest/models/structures/get-institutions-institution-branding */
export type InstitutionBranding = {
    logo?: string
    alternateLogo?: string
    icon?: string
    primaryColor?: string
    tile?: string
}

/** https://api-reference.finicity.com/#/rest/models/structures/institution */
export type Institution = {
    id: number
    name?: string
    transAgg: boolean
    ach: boolean
    stateAgg: boolean
    voi: boolean
    voa: boolean
    aha: boolean
    availBalance: boolean
    accountOwner: boolean
    accountTypeDescription?: string
    phone?: string
    urlHomeApp?: string
    urlLogonApp?: string
    oauthEnabled: boolean
    urlForgotPassword?: string
    urlOnlineRegistration?: string
    class?: string
    specialText?: string
    specialInstructions?: string[]
    address?: InstitutionAddress
    currency: string
    email?: string
    status: string
    newInstitutionId?: number
    branding?: InstitutionBranding
    oauthInstitutionId?: number
}

/** https://api-reference.finicity.com/#/rest/api-endpoints/institutions/get-institutions */
export type GetInstitutionsRequest = {
    search?: string
    start?: number
    limit?: number
}

/** https://api-reference.finicity.com/#/rest/models/structures/get-institutions-response */
export type GetInstitutionsResponse = {
    found: number
    displaying: number
    moreAvailable: boolean
    createdDate: string
    institutions: Institution[]
}
