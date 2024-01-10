import Decimal from 'decimal.js'
import sortBy from 'lodash/sortBy'

export function mean(x: Decimal.Value[]): Decimal {
    if (!x.length) throw new Error('mean requires at least 1 data point')
    return Decimal.sum(...x).div(x.length)
}

export function variance(x: Decimal.Value[]): Decimal {
    const meanValue = mean(x)
    return Decimal.sum(...x.map((k) => Decimal.sub(k, meanValue).pow(2))).div(x.length)
}

export function stddev(x: Decimal.Value[]): Decimal {
    return variance(x).sqrt()
}

export function confidenceInterval(
    x: Decimal.Value[],
    z: Decimal.Value = 1.96 // 90% = 1.645, 95% = 1.96, 99% = 2.58
): [Decimal, Decimal] {
    const meanValue = mean(x)
    const v = Decimal.mul(z, stddev(x).div(Decimal.sqrt(x.length)))
    return [meanValue.minus(v), meanValue.plus(v)]
}

function boxMullerTransform(): [z0: number, z1: number] {
    const u1 = Math.random()
    const u2 = Math.random()

    return [
        Math.sqrt(-2.0 * Math.log(u1)) * Math.cos(2.0 * Math.PI * u2),
        Math.sqrt(-2.0 * Math.log(u1)) * Math.sin(2.0 * Math.PI * u2),
    ]
}

/**
 * Generates random number using normal distribution around a specified mean / stddev
 */
export function randomNormal(mean: Decimal.Value, std: Decimal.Value): Decimal {
    const [z0] = boxMullerTransform()
    return Decimal.mul(z0, std).plus(mean)
}

function countIf<T>(data: T[], fn: (item: T) => boolean): number {
    let count = 0
    for (const item of data) {
        if (fn(item)) count++
    }
    return count
}

/**
 * returns percentage of items meeting a specific criteria
 */
export function rateOf<T>(data: T[], fn: (item: T) => boolean): Decimal {
    return Decimal.div(countIf(data, fn), data.length)
}

export function quantiles(data: Decimal.Value[], p: Decimal.Value[]): Decimal[] {
    const tiles = p.map(_toDecimal)
    const sorted = data.map(_toDecimal).sort((a, b) => a.cmp(b))

    return tiles.map((tile) => _quantileSorted<Decimal>(sorted, tile, mean))
}

export function quantilesBy<T>(data: T[], by: (item: T) => Decimal, p: Decimal.Value[]): T[] {
    const tiles = p.map(_toDecimal)
    const sorted = sortBy(data, (item) => by(item).toNumber())

    return tiles.map((tile) => _quantileSorted<T>(sorted, tile, (data) => data[0]))
}

function _quantileSorted<T>(x: T[], p: Decimal, avg: (data: [T, T]) => T): T {
    const idx = x.length * +p
    if (x.length === 0) {
        throw new Error('quantile requires at least one data point.')
    } else if (p.lt(0) || p.gt(1)) {
        throw new Error('quantiles must be between 0 and 1')
    } else if (p.eq(1)) {
        // If p is 1, directly return the last element
        return x[x.length - 1]
    } else if (p.isZero()) {
        // If p is 0, directly return the first element
        return x[0]
    } else if (idx % 1 !== 0) {
        // If p is not integer, return the next element in array
        return x[Math.ceil(idx) - 1]
    } else if (x.length % 2 === 0) {
        // If the list has even-length, we'll take the average of this number
        // and the next value, if there is one
        return avg([x[idx - 1], x[idx]])
    } else {
        // Finally, in the simple case of an integer value
        // with an odd-length list, return the x value at the index.
        return x[idx]
    }
}

function _toDecimal(x: Decimal.Value): Decimal {
    return x instanceof Decimal ? x : new Decimal(x)
}
