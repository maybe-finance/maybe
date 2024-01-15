// https://teller.io/docs/api/identity

import type { Account } from './accounts'

export type Identity = {
    type: 'person' | 'business'
    names: Name[]
    data: string
    addresses: Address[]
    phone_numbers: PhoneNumber[]
    emails: Email[]
}

type Name = {
    type: 'name' | 'alias'
}

type Address = {
    primary: boolean
    street: string
    city: string
    region: string
    postal_code: string
    country_code: string
}

type Email = {
    data: string
}

type PhoneNumber = {
    type: 'mobile' | 'home' | 'work' | 'unknown'
    data: string
}

export type GetIdentityResponse = {
    account: Account
    owners: Identity[]
}[]
