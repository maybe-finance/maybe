import type { Prisma, Plan, User, PrismaClient, PlanEvent, PlanMilestone } from '@prisma/client'
import { PlanEventFrequency } from '@prisma/client'
import type { SharedType } from '@maybe-finance/shared'
import type { IInsightService } from '../account'
import type { IProjectionCalculator, ProjectionInput, ProjectionSeriesData } from './projection'
import type { PlanTemplate, RetirementTemplate } from './plan.schema'
import Decimal from 'decimal.js'
import { DateTime } from 'luxon'
import _ from 'lodash'
import { DateUtil, PlanUtil, SharedUtil, StatsUtil } from '@maybe-finance/shared'
import { AssetValue, monteCarlo } from './projection'

const PERCENTILES: Decimal[] = ['0.1', '0.9'].map((p) => new Decimal(p))
const MONTE_CARLO_N = 1_000

type PlanWithEventsMilestones = Plan & { events: PlanEvent[]; milestones: PlanMilestone[] }
type PlanWithEventsMilestonesUser = PlanWithEventsMilestones & { user: User }

type ValueRefMap = Record<string, Prisma.Decimal>

function resolveValueRef(valueRef: string, valueRefMap: ValueRefMap): Prisma.Decimal {
    return valueRefMap[valueRef] ?? 0
}

function yearToDate(year: number) {
    return DateTime.fromObject({ year }, { zone: 'utc' }).toISODate()
}

/**
 * Mapping of asset types -> [avg annual return, annual return standard deviation]
 */
const PROJECTION_ASSET_PARAMS: {
    [type in SharedType.ProjectionAssetType]: [mean: Decimal.Value, stddev: Decimal.Value]
} = {
    stocks: ['0.05', '0.186'],
    fixed_income: ['0.02', '0.052'],
    cash: ['-0.02', '0.05'],
    crypto: ['1.0', '1.0'],
    property: ['0.1', '0.2'],
    other: ['-0.02', '0'],
}

export interface IPlanService {
    get(id: Plan['id']): Promise<SharedType.Plan>
    getAll(userId: User['id']): Promise<SharedType.PlansResponse>
    create(data: Prisma.PlanUncheckedCreateInput): Promise<Plan>
    createWithTemplate(user: User, template: PlanTemplate): Promise<SharedType.Plan>
    update(id: Plan['id'], data: Prisma.PlanUncheckedUpdateInput): Promise<SharedType.Plan>
    updateWithTemplate(
        planId: Plan['id'],
        template: PlanTemplate,
        shouldReset?: boolean
    ): Promise<SharedType.Plan>
    delete(id: Plan['id']): Promise<Plan>
    projections(id: Plan['id']): Promise<SharedType.PlanProjectionResponse>
}

export class PlanService implements IPlanService {
    constructor(
        private readonly prisma: PrismaClient,
        private readonly projectionCalculator: IProjectionCalculator,
        private readonly insightService: IInsightService
    ) {}

    async get(id: Plan['id']): Promise<SharedType.Plan> {
        const plan = await this.prisma.plan.findUniqueOrThrow({
            where: { id },
            include: {
                user: true,
                events: true,
                milestones: true,
            },
        })

        return this._mapToSharedPlan(plan, await this._getValueRefMap(plan.user.id))
    }

    async getAll(userId: User['id']): Promise<SharedType.PlansResponse> {
        const [user, plans] = await Promise.all([
            this.prisma.user.findUniqueOrThrow({ where: { id: userId } }),
            this.prisma.plan.findMany({
                where: { userId },
                include: {
                    events: true,
                    milestones: true,
                },
                orderBy: { createdAt: 'desc' },
            }),
        ])

        const insights = await this.insightService.getPlanInsights({ userId: user.id })
        const valueRefMap = this._toValueRefMap(insights)

        return {
            plans: plans.map((plan) => this._mapToSharedPlan(plan, valueRefMap)),
        }
    }

    async create(data: Prisma.PlanUncheckedCreateInput) {
        return this.prisma.plan.create({
            data,
        })
    }

    async createWithTemplate(user: User, template: PlanTemplate) {
        const plan = await this._connectTemplate(template, async (tx, data) => {
            const _plan = await tx.plan.create({ data: { ...data, userId: user.id } })
            return _plan.id
        })

        const insights = await this.insightService.getPlanInsights({ userId: user.id })
        const valueRefMap = this._toValueRefMap(insights)

        return this._mapToSharedPlan(plan, valueRefMap)
    }

    async update(id: Plan['id'], data: Prisma.PlanUncheckedUpdateInput) {
        const plan = await this.prisma.plan.update({
            where: { id },
            include: {
                user: true,
                events: true,
                milestones: true,
            },
            data,
        })

        return this._mapToSharedPlan(plan, await this._getValueRefMap(plan.user.id))
    }

    async updateWithTemplate(planId: Plan['id'], template: PlanTemplate, reset = false) {
        // Clear out previous templates's milestones/events
        if (reset) {
            await this.prisma.plan.update({
                where: { id: planId },
                data: { events: { deleteMany: {} }, milestones: { deleteMany: {} } },
            })
        }

        const plan = await this._connectTemplate(template, planId)
        const insights = await this.insightService.getPlanInsights({ userId: plan.user.id })
        const valueRefMap = this._toValueRefMap(insights)

        return this._mapToSharedPlan(plan, valueRefMap)
    }

    async delete(id: Plan['id']) {
        return this.prisma.plan.delete({ where: { id } })
    }

    async projections(id: Plan['id']) {
        const plan = await this.prisma.plan.findUniqueOrThrow({
            where: { id },
            include: {
                user: true,
                events: true,
                milestones: true,
            },
        })

        const insights = await this.insightService.getPlanInsights({ userId: plan.user.id })

        const age = DateUtil.dobToAge(plan.user.dob) ?? PlanUtil.DEFAULT_AGE

        const inputTheo = this._toProjectionInput(plan, age, insights, false)
        const theo = this.projectionCalculator.calculate(inputTheo)

        const inputRandomized = this._toProjectionInput(plan, age, insights, true)
        const simulations = monteCarlo(() => this.projectionCalculator.calculate(inputRandomized), {
            n: MONTE_CARLO_N,
        })

        const simulationStats = _.zipWith(...simulations, (...series) => {
            const year = series[0].year
            const netWorths = series.map((d) => d.netWorth)
            const successRate = StatsUtil.rateOf(netWorths, (netWorth) => netWorth.gt(0))

            return {
                year,
                percentiles: StatsUtil.quantiles(netWorths, PERCENTILES),
                successRate,
            }
        })

        const simulationsByPercentile = PERCENTILES.map((percentile, idx) => ({
            percentile,
            simulation: simulationStats.map(({ year, percentiles }) => ({
                year,
                netWorth: percentiles[idx],
            })),
        }))

        const planMapped = this._mapToSharedPlan(plan, this._toValueRefMap(insights))

        return {
            input: inputRandomized,
            projection: this._mapToProjectionTimeSeries(theo, simulationStats, planMapped, age),
            simulations: simulationsByPercentile.map(({ percentile, simulation }) => ({
                percentile,
                simulation: this._mapToSimulationTimeSeries(simulation, age),
            })),
        }
    }

    private async _connectTemplate(
        template: PlanTemplate,
        planIdAccessor:
            | ((
                  tx: Prisma.TransactionClient,
                  data: Omit<Prisma.PlanUncheckedCreateInput, 'userId'>
              ) => Promise<Plan['id']>)
            | Plan['id']
    ) {
        return this.prisma.$transaction(async (tx) => {
            let updatedPlan: PlanWithEventsMilestonesUser

            switch (template.type) {
                case 'retirement': {
                    const _planId =
                        typeof planIdAccessor === 'function'
                            ? await planIdAccessor(tx, { name: 'Retirement Plan' })
                            : planIdAccessor

                    updatedPlan = await this._connectRetirementTemplate(tx, _planId, template.data)

                    break
                }
                default: {
                    throw new Error('Template not implemented')
                }
            }

            return updatedPlan
        })
    }

    private async _connectRetirementTemplate(
        tx: Prisma.TransactionClient,
        planId: Plan['id'],
        data: RetirementTemplate & { userAge?: number }
    ) {
        const milestone = await tx.planMilestone.create({
            data: {
                planId,
                name: 'Retirement',
                category: PlanUtil.PlanMilestoneCategory.Retirement,
                type: 'year',
                year: data.retirementYear,
            },
        })

        return await tx.plan.update({
            where: { id: planId },
            data: {
                events: {
                    createMany: {
                        data: [
                            // User's current income, stops at retirement
                            {
                                name: 'Income (current)',
                                endMilestoneId: milestone.id,
                                frequency: PlanEventFrequency.yearly,
                                initialValue: data.annualIncome ? data.annualIncome : undefined,
                                initialValueRef: data.annualIncome ? undefined : 'income',
                            },

                            // User's retirement income - if not specified, we assume no income
                            ...(data.annualRetirementIncome
                                ? [
                                      {
                                          name: 'Income (retirement)',
                                          startMilestoneId: milestone.id,
                                          frequency: PlanEventFrequency.yearly,
                                          initialValue: data.annualRetirementIncome,
                                      },
                                  ]
                                : []),

                            // User's current expenses, stops at retirement
                            {
                                name: 'Expenses (current)',
                                endMilestoneId: milestone.id,
                                frequency: PlanEventFrequency.yearly,
                                initialValue: data.annualExpenses ? data.annualExpenses : undefined,
                                initialValueRef: data.annualExpenses ? undefined : 'expenses',
                            },

                            // User's post-retirement expenses - if not specified, defaults to current expenses
                            {
                                name: 'Expenses (retirement)',
                                startMilestoneId: milestone.id,
                                frequency: PlanEventFrequency.yearly,
                                initialValue: data.annualRetirementExpenses
                                    ? data.annualRetirementExpenses
                                    : undefined,
                                initialValueRef: data.annualRetirementExpenses
                                    ? undefined
                                    : 'expenses',
                            },
                        ],
                    },
                },
            },
            include: {
                user: true,
                events: true,
                milestones: true,
            },
        })
    }

    private _toProjectionInput(
        plan: PlanWithEventsMilestones,
        age: number,
        insights: SharedType.PlanInsights,
        randomized: boolean
    ): ProjectionInput {
        const valueRefMap = this._toValueRefMap(insights)

        return {
            years: plan.lifeExpectancy - age + 1,
            assets: insights.projectionAssetBreakdown.map(({ type, amount }) => {
                const [mean, std] = PROJECTION_ASSET_PARAMS[type]
                return {
                    id: type,
                    value: new AssetValue(amount.toString(), mean, randomized ? std : 0),
                }
            }),
            liabilities: insights.projectionLiabilityBreakdown.map(({ type, amount }) => {
                return {
                    id: type,
                    value: new AssetValue(amount.toString()),
                }
            }),
            events: plan.events.map(
                ({
                    id,
                    startYear,
                    startMilestoneId,
                    endYear,
                    endMilestoneId,
                    frequency,
                    initialValue,
                    initialValueRef,
                    rate,
                }) => {
                    const value = initialValue ?? resolveValueRef(initialValueRef!, valueRefMap)

                    const valueYearly = Decimal.mul(
                        value.toString(),
                        frequency === 'monthly' ? 12 : 1
                    )

                    return {
                        id: id.toString(),
                        value: new AssetValue(valueYearly, rate.toString()),
                        start: startYear ?? startMilestoneId?.toString(),
                        end: endYear ?? endMilestoneId?.toString(),
                    }
                }
            ),
            milestones: plan.milestones.map((milestone) => {
                switch (milestone.type) {
                    case 'year':
                        return {
                            id: milestone.id.toString(),
                            type: 'year',
                            year: milestone.year!,
                        }
                    case 'net_worth':
                        return {
                            id: milestone.id.toString(),
                            type: 'net-worth',
                            expenseMultiple: milestone.expenseMultiple!,
                            expenseYears: milestone.expenseYears!,
                        }
                }
            }),
        }
    }

    private _toValueRefMap(insights: SharedType.PlanInsights): ValueRefMap {
        return {
            income: insights.income.toDP(2),
            expenses: insights.expenses.negated().toDP(2),
        }
    }

    private async _getValueRefMap(userId: User['id']): Promise<ValueRefMap> {
        const insights = await this.insightService.getPlanInsights({ userId })
        return this._toValueRefMap(insights)
    }

    /**
     * Converts a plan to its DTO representation.
     */
    private _mapToSharedPlan(
        plan: Plan & {
            events: PlanEvent[]
            milestones: PlanMilestone[]
        },
        valueRefMap: ValueRefMap
    ): SharedType.Plan {
        return {
            ...plan,
            events: plan.events.map((event) => ({
                ...event,
                initialValue: event.initialValueRef
                    ? resolveValueRef(event.initialValueRef, valueRefMap)
                    : event.initialValue!,
            })),
        }
    }

    private _mapToProjectionTimeSeries(
        theo: ProjectionSeriesData[],
        simulationStats: { year: number; successRate: Decimal }[],
        plan: SharedType.Plan,
        currentAge: number
    ): SharedType.TimeSeries<SharedType.PlanProjectionData> {
        return {
            interval: 'years',
            start: yearToDate(theo[0].year),
            end: yearToDate(theo[theo.length - 1].year),
            data: theo.map((data, idx) => {
                const { successRate } = simulationStats.find((x) => x.year === data.year)!
                return {
                    date: yearToDate(data.year),
                    values: {
                        age: currentAge + idx,
                        year: data.year,
                        netWorth: data.netWorth,
                        events: data.events
                            .map((e) => {
                                const event = plan.events.find((event) => event.id === +e.id)
                                return event ? { event, calculatedValue: e.balance } : undefined
                            })
                            .filter(SharedUtil.nonNull),
                        milestones: data.milestones
                            .map((m) => plan.milestones.find((milestone) => milestone.id === +m.id))
                            .filter(SharedUtil.nonNull),
                        successRate,
                    },
                }
            }),
        }
    }

    private _mapToSimulationTimeSeries(
        simulation: { year: number; netWorth: Decimal }[],
        currentAge: number
    ): SharedType.TimeSeries<SharedType.PlanSimulationData> {
        return {
            interval: 'years',
            start: yearToDate(simulation[0].year),
            end: yearToDate(simulation[simulation.length - 1].year),
            data: simulation.map((data, idx) => ({
                date: yearToDate(data.year),
                values: {
                    age: currentAge + idx,
                    year: data.year,
                    netWorth: data.netWorth,
                },
            })),
        }
    }
}
