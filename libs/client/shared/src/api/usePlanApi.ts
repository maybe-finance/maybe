import type { AxiosInstance } from 'axios'
import type { SharedType } from '@maybe-finance/shared'
import type { UseMutationOptions, UseQueryOptions } from '@tanstack/react-query'
import { useMemo } from 'react'
import toast from 'react-hot-toast'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAxiosWithAuth } from '..'

const PlanApi = (axios: AxiosInstance) => ({
    async getPlans() {
        const { data } = await axios.get<SharedType.PlansResponse>('/plans')
        return data
    },

    async get(id: SharedType.Plan['id']) {
        const { data } = await axios.get<SharedType.Plan>(`/plans/${id}`)
        return data
    },

    async create(input: Record<string, any>) {
        const { data } = await axios.post<SharedType.Plan>('/plans', input)
        return data
    },

    async createTemplate(input: Record<string, any>) {
        const { data } = await axios.post<SharedType.Plan>('/plans/template', input)
        return data
    },

    async update(id: SharedType.Plan['id'], input: Record<string, any>) {
        const { data } = await axios.put<SharedType.Plan>(`/plans/${id}`, input)
        return data
    },

    async updateTemplate(
        id: SharedType.Plan['id'],
        input: Record<string, any>,
        shouldReset?: boolean
    ) {
        const { data } = await axios.put<SharedType.Plan>(`/plans/${id}/template`, input, {
            params: shouldReset ? { reset: shouldReset.toString() } : undefined,
        })
        return data
    },

    async delete(id: SharedType.Plan['id']) {
        const { data } = await axios.delete<SharedType.Plan>(`/plans/${id}`)
        return data
    },

    async projections(id: SharedType.Plan['id']) {
        const { data } = await axios.get<SharedType.PlanProjectionResponse>(
            `/plans/${id}/projections`
        )
        return data
    },
})

const staleTimes = {
    plans: 60_000,
    projections: Infinity, // Will never go stale unless manually invalidated
}

export function usePlanApi() {
    const queryClient = useQueryClient()
    const { axios } = useAxiosWithAuth()
    const api = useMemo(() => PlanApi(axios), [axios])

    const usePlans = (
        options?: Omit<
            UseQueryOptions<SharedType.PlansResponse, unknown, SharedType.PlansResponse, string[]>,
            'queryKey' | 'queryFn' | 'staleTime'
        >
    ) =>
        useQuery(['plans'], api.getPlans, {
            staleTime: staleTimes.plans,
            ...options,
        })

    const usePlan = (
        id: SharedType.Plan['id'],
        options?: Omit<
            UseQueryOptions<SharedType.Plan, unknown, SharedType.Plan, any[]>,
            'queryKey' | 'queryFn' | 'staleTime'
        >
    ) => {
        return useQuery(['plans', id], () => api.get(id), {
            staleTime: staleTimes.plans,
            ...options,
        })
    }

    const useCreatePlan = (
        options?: UseMutationOptions<SharedType.Plan, unknown, Record<string, any>>
    ) =>
        useMutation(api.create, {
            onSuccess: () => {
                toast.success('Plan successfully added!')
            },
            onError: () => {
                toast.error('Error adding plan')
            },
            onSettled: () => {
                queryClient.invalidateQueries(['plans'])
            },
            ...options,
        })

    const useCreatePlanTemplate = (
        options?: UseMutationOptions<SharedType.Plan, unknown, Record<string, any>>
    ) =>
        useMutation(api.createTemplate, {
            onSuccess: () => {
                toast.success('Plan successfully added!')
            },
            onError: () => {
                toast.error('Error adding plan')
            },
            onSettled: () => {
                queryClient.invalidateQueries(['plans'])
            },
            ...options,
        })

    const useUpdatePlanTemplate = () =>
        useMutation(
            ({
                id,
                data,
                shouldReset = false,
            }: {
                id: SharedType.Plan['id']
                data: Record<string, any>
                shouldReset?: boolean
            }) => api.updateTemplate(id, data, shouldReset),
            {
                onSuccess: () => {
                    toast.success('Plan successfully updated!')
                },
                onError: () => {
                    toast.error('Unable to update plan')
                },
                onSettled: () => {
                    queryClient.invalidateQueries(['plans'])
                },
            }
        )

    const useUpdatePlan = () =>
        useMutation(
            ({ id, data }: { id: SharedType.Plan['id']; data: Record<string, any> }) =>
                api.update(id, data),
            {
                onSuccess: () => {
                    toast.success('Plan successfully updated!')
                },
                onError: () => {
                    toast.error('Error updating plan')
                },
                onSettled: () => {
                    queryClient.invalidateQueries(['plans'])
                },
            }
        )

    const useDeletePlan = () =>
        useMutation(api.delete, {
            onSuccess: (data) => {
                toast.success(`${data.name} deleted!`)
            },
            onError: () => {
                toast.error('Failed to delete plan')
            },
            onSettled: () => {
                queryClient.invalidateQueries(['plans'])
            },
        })

    const usePlanProjections = (
        id: SharedType.Plan['id'],
        options?: Omit<
            UseQueryOptions<
                SharedType.PlanProjectionResponse,
                unknown,
                SharedType.PlanProjectionResponse,
                any[]
            >,
            'queryKey' | 'queryFn' | 'staleTime'
        >
    ) => {
        return useQuery(['plans', id, 'projections'], () => api.projections(id), {
            staleTime: staleTimes.projections,
            ...options,
        })
    }

    return {
        usePlans,
        usePlan,
        useCreatePlan,
        useCreatePlanTemplate,
        useUpdatePlan,
        useUpdatePlanTemplate,
        useDeletePlan,
        usePlanProjections,
    }
}
