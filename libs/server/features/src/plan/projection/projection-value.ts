import { StatsUtil } from '@maybe-finance/shared'
import Decimal from 'decimal.js'

export type ProjectionValue = {
    initialValue: Decimal

    /**
     * @param previousValue the value to compute next from (defaults to `initialValue`)
     */
    next(previousValue?: Decimal.Value): Decimal
}

/**
 * Models an asset's value.
 */
export class AssetValue implements ProjectionValue {
    readonly initialValue: Decimal
    readonly rate: Decimal
    readonly stddev: Decimal

    /**
     * @param initialValue initial asset value
     * @param rate average rate of return
     * @param stddev stddev used to simulate rate of return
     */
    constructor(initialValue: Decimal.Value, rate: Decimal.Value = 0, stddev: Decimal.Value = 0) {
        this.initialValue = new Decimal(initialValue)
        this.rate = new Decimal(rate)
        this.stddev = new Decimal(stddev)
    }

    next(previousValue: Decimal.Value = this.initialValue): Decimal {
        // avoid calculating `randomNormal` if stddev=0 for performance
        const rate = this.stddev.isZero()
            ? this.rate
            : StatsUtil.randomNormal(this.rate, this.stddev)

        // need to clamp the minimum rate at -100% since an asset can never lose more than 100% of its value.
        return rate.clamp(-1, Infinity).times(previousValue).plus(previousValue)
    }
}
