export type MetricStatus = 'coming-soon' | 'under-construction' | 'active'

export type ClientSideFeatureFlag = Partial<{
    maintenance: boolean
}>
