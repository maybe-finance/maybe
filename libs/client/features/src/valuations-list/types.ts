import type { SharedType } from '@maybe-finance/shared'
import type { DateTime } from 'luxon'

export interface ValuationRowData {
    date: DateTime
    type: 'manual' | 'trend' | 'initial'
    amount: SharedType.Decimal
    period: SharedType.Trend
    total: SharedType.Trend
    valuationId?: number
    accountId?: number
}
