import type { SharedType } from '..'
import type { PlanProjectionResponse } from '../types'

export const DEFAULT_AGE = 30
export const DEFAULT_LIFE_EXPECTANCY = 85
export const CONFIDENCE_INTERVAL = 0.9
export const RETIREMENT_MILESTONE_AGE = 65

export enum PlanEventCategory {}
export enum PlanMilestoneCategory {
    Retirement = 'retirement',
    FI = 'fi',
}

export function resolveMilestoneYear(
    projection: PlanProjectionResponse['projection'],
    id: SharedType.PlanMilestone['id']
): number | undefined {
    return projection.data.find((d) => d.values.milestones.some((m) => m.id === id))?.values.year
}
