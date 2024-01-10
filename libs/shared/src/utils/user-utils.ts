export const MAX_MAYBE_LENGTH = 180

export const userTitles = [
    'DIY Investor',
    'Internet Businessman',
    'Soon-to-be Millionaire',
    'Inevitable Billionaire',
    'Passive Income Pro',
    'Curious Self-Starter',
    'Crypto Whale',
    'Complete Degen',
    'Stock Market Maverick',
    'Wall Street Insider',
    'NFT Collector',
    'Real Estate Mogul',
    'Diamond Hands',
    'Savings Savant',
    'Aspiring Retiree',
    'FIRE seeker',
    'FatFIRE hopeful',
    'Credit Card Connoisseur',
    'Debt Destroyer',
    'Investing Novice',
    'Economic Enthusiast',
    'Freedom Seeker',
    'Bootstrapped Founder',
    'Smart Saver',
    'Wealth Builder',
    'Budget Master',
    'Financial Freedom Fighter',
    'Stock Market Enthusiast',
    'Savvy Spender',
]

export const randomUserTitle = (except?: string) =>
    userTitles.filter((title) => title !== except)[
        Math.floor(Math.random() * (userTitles.length - (except ? 1 : 0)))
    ]
