import { getPolygonTicker } from './market-data.service'
import { AssetClass } from '@prisma/client'

describe('PolygonMarketDataService', () => {
    it.each`
        assetClass            | symbol                   | ticker
        ${AssetClass.stocks}  | ${'AAPL'}                | ${{ market: 'stocks', ticker: 'AAPL' }}
        ${AssetClass.other}   | ${'AAPL'}                | ${{ market: 'stocks', ticker: 'AAPL' }}
        ${AssetClass.options} | ${'AAPL220909C00070000'} | ${{ market: 'options', ticker: 'O:AAPL220909C00070000' }}
        ${AssetClass.other}   | ${'AAPL220909C00070000'} | ${{ market: 'options', ticker: 'O:AAPL220909C00070000' }}
        ${AssetClass.crypto}  | ${'BTC'}                 | ${{ market: 'crypto', ticker: 'X:BTCUSD' }}
        ${AssetClass.cash}    | ${'USD'}                 | ${null}
        ${AssetClass.cash}    | ${'EUR'}                 | ${{ market: 'fx', ticker: 'C:EURUSD' }}
    `(
        'properly parses security symbol: $symbol assetClass: $assetClass',
        ({ assetClass, symbol, ticker }) => {
            expect(getPolygonTicker({ assetClass, currencyCode: 'USD', symbol })).toEqual(ticker)
        }
    )
})
