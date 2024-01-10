import type { Prisma } from '@prisma/client'

export type InsightState = 'healthy' | 'review' | 'at-risk' | 'excessive'

export const InsightStateNames: Record<InsightState, string> = {
    healthy: 'Healthy',
    review: 'Review',
    'at-risk': 'At risk',
    excessive: 'Excessive',
}

export const InsightStateColors: Record<InsightState, 'teal' | 'yellow' | 'red'> = {
    healthy: 'teal',
    review: 'yellow',
    'at-risk': 'red',
    excessive: 'yellow',
}

export const InsightStateColorClasses: Record<InsightState, string> = {
    healthy: 'text-teal',
    review: 'text-yellow',
    'at-risk': 'text-red',
    excessive: 'text-yellow',
}

export function safetyNetState(months: Prisma.Decimal): InsightState {
    if (months.gt(12)) return 'excessive'
    if (months.gte(6)) return 'healthy'
    if (months.gte(3)) return 'review'
    return 'at-risk'
}

export function incomePayingDebtState(debtIncomeRatio: Prisma.Decimal): InsightState {
    if (debtIncomeRatio.lt(0.25)) return 'healthy'
    if (debtIncomeRatio.lt(0.36)) return 'review'
    return 'at-risk'
}
