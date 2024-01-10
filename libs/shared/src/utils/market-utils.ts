// Option ticker reference: https://www.investopedia.com/ask/answers/05/052505.asp

export function isOptionTicker(ticker: string): boolean {
    return ticker.length >= 16
}

export function getUnderlyingTicker(ticker: string): string | null {
    return ticker.length >= 16 ? ticker.slice(0, -15).trim() : null
}
