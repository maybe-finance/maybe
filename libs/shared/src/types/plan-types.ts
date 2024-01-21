import type {
    Prisma,
    Plan as PrismaPlan,
    PlanEvent as PrismaPlanEvent,
    PlanMilestone as PrismaPlanMilestone,
} from '@prisma/client'
import type { O } from 'ts-toolbelt'
import type { Decimal, TimeSeries } from './general-types'

export type PlanEvent = O.NonNullable<PrismaPlanEvent, 'initialValue'>
export type PlanMilestone = PrismaPlanMilestone

export type Plan = PrismaPlan & {
    events: PlanEvent[]
    milestones: PlanMilestone[]
}

export type PlansResponse = {
    plans: Plan[]
}

export type PlanProjectionEvent = {
    event: PlanEvent
    calculatedValue: Decimal
}

export type PlanProjectionMilestone = PlanMilestone

export type PlanProjectionData = {
    date: string
    values: {
        year: number
        age: number
        netWorth: Decimal
        events: PlanProjectionEvent[]
        milestones: PlanProjectionMilestone[]
        successRate: Decimal
    }
}

export type PlanSimulationData = {
    date: string
    values: {
        year: number
        age: number
        netWorth: Decimal
    }
}

// API response
export type PlanProjectionResponse = {
    projection: TimeSeries<PlanProjectionData>
    simulations: {
        percentile: Decimal
        simulation: TimeSeries<PlanSimulationData>
    }[]
}

export type ProjectionAssetType =
    | 'stocks'
    | 'fixed_income'
    | 'cash'
    | 'crypto'
    | 'property'
    | 'other'
export type ProjectionLiabilityType = 'credit' | 'loan' | 'other'

export type PlanInsights = {
    projectionAssetBreakdown: {
        type: ProjectionAssetType
        amount: Prisma.Decimal
    }[]
    projectionLiabilityBreakdown: {
        type: ProjectionLiabilityType
        amount: Prisma.Decimal
    }[]
    income: Prisma.Decimal
    expenses: Prisma.Decimal
}
