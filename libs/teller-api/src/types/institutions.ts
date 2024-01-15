// https://api.teller.io/institutions
// Note: Teller says this is subject to change, specifically the `capabilities` field

export type Institution = {
    id: string
    name: string
    capabilities: Capability[]
}

type Capability = 'detail' | 'balance' | 'transaction' | 'identity'

export type GetInstitutionsResponse = {
    institutions: Institution[]
}
