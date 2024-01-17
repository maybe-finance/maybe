export function getDateFormatByCountryCode(countryCode: string): string {
    let dateFormat = ''
    switch (countryCode.toLowerCase()) {
        case 'in':
            dateFormat = 'dd / MM / yyyy'
            break
        case 'us':
            dateFormat = 'yyyy / MM / dd'
            break
        default:
            dateFormat = 'dd / MM / yyyy'
            break
    }

    return dateFormat
}
