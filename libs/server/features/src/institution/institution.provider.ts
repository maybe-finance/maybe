import type { Prisma, Provider } from '@prisma/client'

export interface IInstitutionProvider {
    getInstitutions(): Promise<Omit<Prisma.ProviderInstitutionUncheckedCreateInput, 'provider'>[]>
}

export interface IInstitutionProviderFactory {
    for(provider: Provider): IInstitutionProvider
}

export class InstitutionProviderFactory implements IInstitutionProviderFactory {
    constructor(private readonly providers: Record<Provider, IInstitutionProvider>) {}

    for(p: Provider): IInstitutionProvider {
        const provider = this.providers[p]
        if (!provider) throw new Error(`Unsupported provider: ${p}`)
        return provider
    }
}
