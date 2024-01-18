import { useMemo } from 'react'
import type { SharedType } from '@maybe-finance/shared'

type GridImage = {
    src: string
    alt: string
    institution?: Pick<SharedType.ProviderInstitution, 'provider' | 'providerId'>
}

const BASE_IMAGES_FOLDER = '/assets/images/financial-institutions/'

const banks: GridImage[] = [
    {
        src: 'chase-bank.png',
        alt: 'Chase Bank',
        institution: {
            provider: 'TELLER',
            providerId: 'chase',
        },
    },
    {
        src: 'capital-one.png',
        alt: 'Capital One Bank',
        institution: {
            provider: 'TELLER',
            providerId: 'capital_one',
        },
    },
    {
        src: 'wells-fargo.png',
        alt: 'Wells Fargo Bank',
        institution: {
            provider: 'TELLER',
            providerId: 'wells_fargo',
        },
    },
    {
        src: 'american-express.png',
        alt: 'American Express Bank',
        institution: {
            provider: 'TELLER',
            providerId: 'amex',
        },
    },
    {
        src: 'bofa.png',
        alt: 'Bank of America',
        institution: {
            provider: 'TELLER',
            providerId: 'bank_of_america',
        },
    },
    {
        src: 'usaa-bank.png',
        alt: 'USAA Bank',
        institution: {
            provider: 'TELLER',
            providerId: 'usaa',
        },
    },
]

const brokerages: GridImage[] = [
    {
        src: 'robinhood.png',
        alt: 'Robinhood',
        institution: {
            provider: 'PLAID',
            providerId: 'ins_54',
        },
    },
    {
        src: 'wealthfront.png',
        alt: 'Wealthfront',
        institution: {
            provider: 'PLAID',
            providerId: 'ins_115617',
        },
    },
    {
        src: 'betterment.png',
        alt: 'Betterment',
        institution: {
            provider: 'PLAID',
            providerId: 'ins_115605',
        },
    },
    {
        src: 'interactive-brokers.png',
        alt: 'Interactive Brokers',
        institution: {
            provider: 'PLAID',
            providerId: 'ins_116530',
        },
    },
]

const cryptoExchanges: GridImage[] = [
    { src: 'coinbase.png', alt: 'Coinbase' },
    { src: 'binance.png', alt: 'Binance' },
    { src: 'cash-app.png', alt: 'Cash App' },
    { src: 'kraken.png', alt: 'Kraken' },
    { src: 'crypto-dot-com.png', alt: 'Crypto Dot Com' },
    { src: 'ftx.png', alt: 'FTX Exchange' },
]

export default function InstitutionGrid({
    type,
    onClick,
}: {
    type: 'crypto' | 'banks' | 'brokerages'
    onClick: (
        institution?: Pick<SharedType.ProviderInstitution, 'provider' | 'providerId'>,
        cryptoExchangeName?: string
    ) => void
}) {
    const imageList = useMemo(() => {
        switch (type) {
            case 'crypto':
                return cryptoExchanges
            case 'brokerages':
                return brokerages
            case 'banks':
                return banks
        }
    }, [type])

    return (
        <div className="grid grid-cols-2 gap-4">
            {imageList.map((img) => (
                <img
                    className="cursor-pointer hover:opacity-90 w-[193px] h-[116px]"
                    key={img.alt}
                    src={`${BASE_IMAGES_FOLDER}${img.src}`}
                    alt={img.alt}
                    onClick={() => {
                        switch (type) {
                            case 'crypto':
                                onClick(undefined, img.alt)
                                break
                            case 'brokerages':
                            case 'banks':
                                onClick(img.institution)
                                break
                            default:
                                throw new Error('Invalid institution type')
                        }
                    }}
                />
            ))}
        </div>
    )
}
