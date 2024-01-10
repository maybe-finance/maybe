import { getPolygonTicker } from './market-data.service'

describe('PolygonMarketDataService', () => {
    it.each`
        symbol                   | plaidType           | ticker
        ${'AAPL'}                | ${'equity'}         | ${{ market: 'stocks', ticker: 'AAPL' }}
        ${'AAPL'}                | ${null}             | ${{ market: 'stocks', ticker: 'AAPL' }}
        ${'AAPL220909C00070000'} | ${'derivative'}     | ${{ market: 'options', ticker: 'O:AAPL220909C00070000' }}
        ${'AAPL220909C00070000'} | ${null}             | ${{ market: 'options', ticker: 'O:AAPL220909C00070000' }}
        ${'BTC'}                 | ${'cryptocurrency'} | ${{ market: 'crypto', ticker: 'X:BTCUSD' }}
        ${'CUR:BTC'}             | ${'cash'}           | ${{ market: 'crypto', ticker: 'X:BTCUSD' }}
        ${'CUR:USD'}             | ${'cash'}           | ${null}
        ${'USD'}                 | ${'cash'}           | ${null}
        ${'EUR'}                 | ${'cash'}           | ${{ market: 'fx', ticker: 'C:EURUSD' }}
    `(
        'properly parses security symbol: $symbol plaidType: $plaidType',
        ({ symbol, plaidType, ticker }) => {
            expect(getPolygonTicker({ symbol, plaidType, currencyCode: 'USD' })).toEqual(ticker)
        }
    )
})
