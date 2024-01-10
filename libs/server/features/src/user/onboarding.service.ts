import type { SharedType } from '@maybe-finance/shared'

export type RegisteredStep = {
    key: string
    markedComplete: boolean
}

// DB Json field where each key represents a separate onboarding flow
export type OnboardingState = {
    [key in SharedType.OnboardingFlow]: {
        markedComplete: boolean // An override to indicate the flow is complete
        steps: RegisteredStep[]
    }
}

type CallbackFn<TData = unknown, T = boolean> = (user: TData, step: Step<TData>) => T

export class Step<TData = unknown> {
    group: string | undefined
    ctaPath: string | undefined
    title!: CallbackFn<TData, string>
    isComplete!: CallbackFn<TData>
    isMarkedComplete: CallbackFn<TData> = () => false
    isExcluded: CallbackFn<TData> = () => false
    isOptional = false

    /**
     * Constructs an onboarding step
     * @param key a stable key that the UI relies to show relevant view components
     * @param group a grouping that UI uses to visually group steps as "substeps"
     */
    constructor(readonly key: string) {}

    addToGroup(group: string) {
        this.group = group
        return this
    }

    /** When clicked, the router path that app will redirect to */
    setCTAPath(path: string) {
        this.ctaPath = path
        return this
    }

    setTitle(fn: CallbackFn<TData, string>) {
        this.title = fn
        return this
    }

    completeIf(fn: CallbackFn<TData>) {
        this.isComplete = fn
        return this
    }

    markedCompleteIf(fn: CallbackFn<TData>) {
        this.isMarkedComplete = fn
        return this
    }

    excludeIf(fn: CallbackFn<TData>) {
        this.isExcluded = fn
        return this
    }

    optional() {
        this.isOptional = true
        return this
    }
}

export class Onboarding<TData = unknown> {
    private _steps: Step<TData>[] = []

    constructor(
        private readonly data: TData,
        private readonly onboardingCompleteOverride: boolean
    ) {
        if (!this._steps.every((step) => step.completeIf != null && step.title != null)) {
            throw new Error('Every step must define completeIf callback fn and title')
        }
    }

    get isComplete() {
        return this.steps.every(
            (step) => step.isComplete || step.isOptional || step.isMarkedComplete
        )
    }

    get isMarkedComplete() {
        return this.steps.every((step) => step.isMarkedComplete) || this.onboardingCompleteOverride
    }

    /** Progress, expressed as percentage. */
    get progress() {
        const completed = this.steps.filter(
            (step) => step.isComplete || step.isMarkedComplete
        ).length

        return {
            completed,
            total: this.steps.length,
            percent: +(completed / this.steps.length).toFixed(2),
        }
    }

    get steps() {
        return this._steps
            .filter((step) => !step.isExcluded(this.data, step))
            .map((step) => ({
                key: step.key,
                title: step.title(this.data, step),
                group: step.group,
                ctaPath: step.ctaPath,
                isOptional: step.isOptional,
                isComplete: step.isComplete(this.data, step),
                isMarkedComplete: step.isMarkedComplete(this.data, step),
            }))
    }

    get currentStep() {
        const incompleteSteps = this.steps.filter((step) => !step.isComplete)
        return incompleteSteps[0]
    }

    addStep(key: string) {
        const step = new Step<TData>(key)
        this._steps.push(step)
        return step
    }
}
