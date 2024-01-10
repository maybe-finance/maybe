import type { SharedType } from '@maybe-finance/shared'
import { createContext, useContext } from 'react'

export type PlanContext = {
    userAge: number
    planStartYear: number
    planEndYear: number
    milestones: SharedType.PlanMilestone[]
}

export const PlanContext = createContext<PlanContext | undefined>(undefined)

export function usePlanContext() {
    const ctx = useContext(PlanContext)

    if (!ctx) throw new Error('Must use usePlanContext inside PlanContext.Provider')

    return ctx
}
