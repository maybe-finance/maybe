import type { AgreementType } from '@prisma/client'

export function agreementName(type: AgreementType): string {
    switch (type) {
        case 'fee':
            return 'Limited Scope Advisory Agreement'
        case 'form_adv_2a':
            return 'Form ADV Part 2A'
        case 'form_adv_2b':
            return 'Form ADV Part 2B'
        case 'form_crs':
            return 'Form CRS'
        case 'privacy_policy':
            return 'Advisor Privacy Policy'
        default:
            return type
    }
}
