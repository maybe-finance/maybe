import type { ProjectionValue } from './projection-value'
import type Decimal from 'decimal.js'
import { DateTime } from 'luxon'
import { NumberUtil } from '@maybe-finance/shared'
import range from 'lodash/range'

export type ProjectionAsset = {
    id: string
    value: ProjectionValue
}

export type ProjectionLiability = {
    id: string
    value: ProjectionValue
}

export type ProjectionMilestone = {
    id: string
} & (
    | {
          type: 'year'
          year: number
      }
    | {
          type: 'net-worth'
          expenseMultiple: number
          expenseYears: number
      }
)

export type ProjectionEvent = {
    id: string
    value: ProjectionValue
    start?: number | ProjectionMilestone['id'] | null
    end?: number | ProjectionMilestone['id'] | null
}

export type ProjectionInput = {
    years: number
    assets: ProjectionAsset[]
    liabilities: ProjectionLiability[]
    events: ProjectionEvent[]
    milestones: ProjectionMilestone[]
}

export type ProjectionSeriesData = {
    year: number
    netWorth: Decimal
    assets: { id: ProjectionAsset['id']; balance: Decimal }[]
    liabilities: { id: ProjectionLiability['id']; balance: Decimal }[]
    events: { id: ProjectionEvent['id']; balance: Decimal }[]
    milestones: { id: ProjectionMilestone['id'] }[]
}

export interface IProjectionCalculator {
    calculate(input: ProjectionInput, now?: DateTime): ProjectionSeriesData[]
}

export class ProjectionCalculator implements IProjectionCalculator {
    calculate(input: ProjectionInput, now = DateTime.now()): ProjectionSeriesData[] {
        const initialAssets = NumberUtil.sumBy(input.assets, (a) => a.value.initialValue)
        const assetsWithAllocation = input.assets.map((asset) => ({
            ...asset,
            allocation: asset.value.initialValue.dividedBy(initialAssets),
        }))

        const milestones: { id: ProjectionMilestone['id']; year: number }[] = input.milestones
            .filter((m): m is Extract<ProjectionMilestone, { type: 'year' }> => m.type === 'year')
            .map((m) => ({ id: m.id, year: m.year }))

        return range(input.years).reduce((acc, t) => {
            const year = now.year + t

            // events
            const events = input.events
                .filter((e) => this.isActive(e, year, milestones))
                .map((event) => {
                    if (t === 0) {
                        return { id: event.id, balance: event.value.initialValue }
                    }

                    const balancePrev = acc[t - 1]!.events.find((e) => e.id === event.id)?.balance

                    return {
                        id: event.id,
                        balance: event.value.next(balancePrev),
                    }
                })
            const netEvents = NumberUtil.sumBy(events, (e) => e.balance)

            // assets
            const assets = assetsWithAllocation.map((asset) => {
                if (t === 0) {
                    return {
                        id: asset.id,
                        balance: asset.value.initialValue,
                    }
                }

                // in order to determine this asset's last balance we assume a constant allocation
                // of contributions (ie. netEventsPrev) based on the initial (t0) allocation
                // that way we don't have to do any manual "rebalancing" of the asset portfolio
                const netAssetsPrev = NumberUtil.sumBy(acc[t - 1]!.assets, (a) => a.balance)
                const netEventsPrev = NumberUtil.sumBy(acc[t - 1]!.events, (e) => e.balance)
                const balancePrev = netAssetsPrev.plus(netEventsPrev).times(asset.allocation)

                return {
                    id: asset.id,
                    balance: asset.value.next(balancePrev),
                }
            })
            const assetsTotal = NumberUtil.sumBy(assets, (a) => a.balance)

            // liabilities
            const liabilities = input.liabilities.map((liability, idx) => {
                if (t === 0) {
                    return {
                        id: liability.id,
                        balance: liability.value.initialValue,
                    }
                }

                // ToDo: update this logic to apply "payments" made each year towards this liability (via `netEventsPrev`) so that the balance goes down over time.
                // - we'll need to figure out priority for how excess money gets distributed between assets vs liabilities
                // - ProjectionLab handles this by allowing user to allocate $X/yr to each liability, or specify a payment plan (eg. "Pay over 10 years"), or specify % of excess cash that gets put towards paying down debt
                const balancePrev = acc[t - 1]!.liabilities[idx]!.balance

                return {
                    id: liability.id,
                    balance: liability.value.next(balancePrev),
                }
            })
            const liabilitiesTotal = NumberUtil.sumBy(liabilities, (l) => l.balance)

            const netWorth = assetsTotal.minus(liabilitiesTotal).plus(netEvents)

            // milestones
            milestones.push(
                ...input.milestones
                    .filter(({ id }) => !milestones.some((m) => m.id === id))
                    .map((milestone) => {
                        switch (milestone.type) {
                            case 'net-worth': {
                                const data = acc.slice(-milestone.expenseYears)
                                const target = NumberUtil.sumBy(data, ({ events }) =>
                                    NumberUtil.sumBy(
                                        events.filter((e) => e.balance.lt(0)),
                                        (e) => e.balance.abs()
                                    )
                                )
                                    .dividedBy(data.length)
                                    .times(milestone.expenseMultiple)

                                return {
                                    id: milestone.id,
                                    year: netWorth.gte(target) ? year : null,
                                }
                            }
                            default:
                                return { id: milestone.id, year: milestone.year }
                        }
                    })
                    .filter((m): m is typeof milestones[0] => m.year != null)
            )

            acc.push({
                year,
                netWorth,
                assets,
                liabilities,
                events,
                milestones: milestones.filter((m) => m.year === year),
            })

            return acc
        }, [] as ProjectionSeriesData[])
    }

    private isActive(
        event: ProjectionEvent,
        year: number,
        milestones: { id: ProjectionMilestone['id']; year: number }[]
    ): boolean {
        const hasStarted =
            event.start == null ||
            (typeof event.start === 'number' && year >= event.start) ||
            (typeof event.start === 'string' &&
                milestones.some((m) => m.id === event.start && year >= m.year))

        const hasEnded =
            (typeof event.end === 'number' && year > event.end) ||
            (typeof event.end === 'string' &&
                milestones.some((m) => m.id === event.end && year > m.year))

        return hasStarted && !hasEnded
    }
}
