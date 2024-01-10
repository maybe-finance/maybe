/** https://api-reference.finicity.com/#/rest/models/structures/add-customer-request */
export type AddCustomerRequest = {
    username: string
    firstName?: string
    lastName?: string
    applicationId?: string
}

/** https://api-reference.finicity.com/#/rest/models/structures/add-customer-response */
export type AddCustomerResponse = {
    id: string
    username: string
    createdDate: string
}
