import type {
    Institution as PrismaInstitution,
    ProviderInstitution as PrismaProviderInstitution,
} from '@prisma/client'

export type ProviderInstitution = Pick<
    PrismaProviderInstitution,
    'id' | 'provider' | 'providerId' | 'rank'
>

export type Institution = Pick<
    PrismaInstitution | PrismaProviderInstitution,
    'name' | 'url' | 'logo' | 'logoUrl' | 'primaryColor'
> & {
    id: string | number // we allow a `string` ID so we can construct artifical IDs for Institutions backed by a ProviderInstitution
    providers: ProviderInstitution[]
}

export type InstitutionsResponse = {
    institutions: Institution[]
    totalInstitutions: number
}
