import type { Holding } from '@prisma/client'
import type { AxiosInstance } from 'axios'
import type { UseMutationOptions, UseQueryOptions } from '@tanstack/react-query'
import type { SharedType } from '@maybe-finance/shared'
import { useMemo } from 'react'
import toast from 'react-hot-toast'
import { useMutation, useQueryClient, useQuery } from '@tanstack/react-query'
import { useAxiosWithAuth } from '..'
import { invalidateAccountQueries } from '../utils'

const HoldingApi = (axios: AxiosInstance) => ({
    async getHolding(id: Holding['id']) {
        const { data } = await axios.get<SharedType.AccountHolding>(`/holdings/${id}`)
        return data
    },

    async getInsights(id: Holding['id']) {
        const { data } = await axios.get<SharedType.HoldingInsights>(`/holdings/${id}/insights`)
        return data
    },

    async update(id: Holding['id'], input: Record<string, any>) {
        const { data } = await axios.put<Holding>(`/holdings/${id}`, input)
        return data
    },
})

export function useHoldingApi() {
    const queryClient = useQueryClient()
    const { axios } = useAxiosWithAuth()
    const api = useMemo(() => HoldingApi(axios), [axios])

    const useHolding = (
        id: Holding['id'],
        options?: Omit<
            UseQueryOptions<SharedType.AccountHolding, unknown, SharedType.AccountHolding, any[]>,
            'queryKey' | 'queryFn' | 'staleTime'
        >
    ) => {
        return useQuery(['holdings', id], () => api.getHolding(id), {
            staleTime: 30_000,
            ...options,
        })
    }

    const useHoldingInsights = (
        id: Holding['id'],
        options?: Omit<
            UseQueryOptions<SharedType.HoldingInsights, unknown, SharedType.HoldingInsights, any[]>,
            'queryKey' | 'queryFn' | 'staleTime'
        >
    ) => {
        return useQuery(['holdings', id, 'insights'], () => api.getInsights(id), {
            staleTime: 30_000,
            ...options,
        })
    }

    const useUpdateHolding = (
        options?: UseMutationOptions<Holding, unknown, Record<string, any>>
    ) =>
        useMutation(
            ({ id, data }: { id: Holding['id']; data: Record<string, any> }) =>
                api.update(id, data),
            {
                onSuccess: () => {
                    toast.success('Holding successfully updated!')
                },
                onError: () => {
                    toast.error('Error updating holding')
                },
                onSettled: () => {
                    invalidateAccountQueries(queryClient)
                    queryClient.invalidateQueries(['holdings'])
                },
                ...options,
            }
        )

    return {
        useHolding,
        useHoldingInsights,
        useUpdateHolding,
    }
}
