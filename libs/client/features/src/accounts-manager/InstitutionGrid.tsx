import { BrowserUtil } from '@maybe-finance/client/shared'
import { useMemo } from 'react'
import Image from 'next/legacy/image'
import type { SharedType } from '@maybe-finance/shared'

type GridImage = {
    src: string
    alt: string
    institution?: Pick<SharedType.ProviderInstitution, 'provider' | 'providerId'>
}

const banks: GridImage[] = [
    {
        src: 'chase-bank.png',
        alt: 'Chase Bank',
        institution: {
            provider: 'PLAID',
            providerId: 'ins_56',
        },
    },
    {
        src: 'capital-one.png',
        alt: 'Capital One Bank',
        institution: {
            provider: 'PLAID',
            providerId: 'ins_128026',
        },
    },
    {
        src: 'wells-fargo.png',
        alt: 'Wells Fargo Bank',
        institution: {
            provider: 'PLAID',
            providerId: 'ins_127991',
        },
    },
    {
        src: 'american-express.png',
        alt: 'American Express Bank',
        institution: {
            provider: 'PLAID',
            providerId: 'ins_10',
        },
    },
    {
        src: 'bofa.png',
        alt: 'Bank of America',
        institution: {
            provider: 'PLAID',
            providerId: 'ins_127989',
        },
    },
    {
        src: 'usaa-bank.png',
        alt: 'USAA Bank',
        institution: {
            provider: 'PLAID',
            providerId: 'ins_7',
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
        src: 'fidelity.png',
        alt: 'Fidelity',
        institution: {
            provider: 'FINICITY',
            providerId: '9913',
        },
    },
    {
        src: 'vanguard.png',
        alt: 'Vanguard',
        institution: {
            provider: 'FINICITY',
            providerId: '3078',
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
                <Image
                    className="cursor-pointer hover:opacity-90"
                    key={img.alt}
                    loader={BrowserUtil.enhancerizerLoader}
                    src={`financial-institutions/${img.src}`}
                    alt={img.alt}
                    layout="responsive"
                    width={193}
                    height={116}
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
