import type { AxiosInstance } from 'axios'
import type { Account } from '@prisma/client'
import type { SharedType } from '@maybe-finance/shared'
import type { UseMutationOptions, UseQueryOptions } from '@tanstack/react-query'

import { useMemo } from 'react'
import { DateTime } from 'luxon'
import toast from 'react-hot-toast'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAxiosWithAuth } from '..'
import { invalidateAccountQueries } from '../utils'

const ValuationApi = (axios: AxiosInstance) => ({
    async create(accountId: SharedType.Account['id'], input: Record<string, any>) {
        const { data } = await axios.post<SharedType.Valuation>(
            `/accounts/${accountId}/valuations`,
            input
        )
        return data
    },

    async update(id: SharedType.Valuation['id'], input: Record<string, any>) {
        const { data } = await axios.put<SharedType.Valuation>(`/valuations/${id}`, input)
        return data
    },

    async delete(id: SharedType.Valuation['id']) {
        const { data } = await axios.delete<SharedType.Valuation>(`/valuations/${id}`)
        return data
    },

    async getValuations(
        id: SharedType.Account['id'],
        start?: string,
        end?: string
    ): Promise<SharedType.AccountValuationsResponse> {
        const { data } = await axios.get<SharedType.AccountValuationsResponse>(
            `/accounts/${id}/valuations`,
            {
                params: { start, end },
            }
        )

        return data
    },
})

const staleTimes = {
    valuations: 30000,
}

export function useValuationApi() {
    const queryClient = useQueryClient()
    const { axios } = useAxiosWithAuth()
    const api = useMemo(() => ValuationApi(axios), [axios])

    const useCreateValuation = (
        options?: UseMutationOptions<SharedType.Valuation, unknown, Record<string, any>>
    ) =>
        useMutation(
            ({ id, data }: { id: SharedType.Account['id']; data: Record<string, any> }) =>
                api.create(id, data),
            {
                ...options,
                onSuccess: (...args) => {
                    toast.success('Valuation successfully added!')
                    if (options?.onSuccess) options.onSuccess(...args)
                },
                onError: (...args) => {
                    toast.error('Error adding valuation')
                    if (options?.onError) options.onError(...args)
                },
                onSettled: () => {
                    invalidateAccountQueries(queryClient)
                },
            }
        )

    const useUpdateValuation = (
        options?: UseMutationOptions<SharedType.Valuation, unknown, Record<string, any>>
    ) =>
        useMutation(
            ({ id, data }: { id: SharedType.Valuation['id']; data: Record<string, any> }) =>
                api.update(id, data),
            {
                onSuccess: (...args) => {
                    toast.success('Valuation successfully updated!')
                    if (options?.onSuccess) options.onSuccess(...args)
                },
                onError: (...args) => {
                    toast.error('Error updating valuation')
                    if (options?.onError) options.onError(...args)
                },
                onSettled: () => {
                    queryClient.invalidateQueries(['accounts'])
                },
            }
        )

    const useDeleteValuation = (
        options?: UseMutationOptions<SharedType.Valuation, unknown, Record<string, any>>
    ) =>
        useMutation(({ id }: { id: SharedType.Valuation['id'] }) => api.delete(id), {
            onSuccess: (...args) => {
                toast.success(
                    `Valuation for ${DateTime.fromJSDate(args[0].date, { zone: 'utc' }).toFormat(
                        'MMM d, yyyy'
                    )} deleted!`
                )
                if (options?.onSuccess) options.onSuccess(...args)
            },
            onError: (...args) => {
                toast.error('Failed to delete valuation')
                if (options?.onError) options.onError(...args)
            },
            onSettled: () => {
                invalidateAccountQueries(queryClient)
            },
        })

    const useAccountValuations = (
        {
            id,
            start,
            end,
        }: {
            id: Account['id']
            start?: string
            end?: string
        },
        options: Omit<
            UseQueryOptions<
                SharedType.AccountValuationsResponse,
                unknown,
                SharedType.AccountValuationsResponse,
                any[]
            >,
            'queryKey' | 'queryFn'
        >
    ) => {
        const queryKey = ['accounts', id, 'valuations']

        if (start && end) {
            queryKey.push({ start, end } as any)
        }

        return useQuery(queryKey, () => api.getValuations(id, start, end), {
            staleTime: staleTimes.valuations,
            ...options,
        })
    }

    return {
        useAccountValuations,
        useCreateValuation,
        useUpdateValuation,
        useDeleteValuation,
    }
}
