import type { AxiosInstance } from 'axios'
import type { Transaction } from '@prisma/client'
import type { UseMutationOptions, UseQueryOptions } from '@tanstack/react-query'
import type { SharedType } from '@maybe-finance/shared'
import { useMemo } from 'react'
import toast from 'react-hot-toast'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAxiosWithAuth } from '..'

const TransactionApi = (axios: AxiosInstance) => ({
    async getAll(pageIndex: number, pageSize: number) {
        const { data } = await axios.get<SharedType.TransactionsResponse>('/transactions', {
            params: { pageIndex, pageSize },
        })
        return data
    },

    async get(id: SharedType.Transaction['id']): Promise<SharedType.TransactionWithAccountDetail> {
        const { data } = await axios.get<SharedType.TransactionWithAccountDetail>(
            `/transactions/${id}`
        )
        return data
    },

    async update(id: SharedType.Transaction['id'], input: Record<string, any>) {
        const { data } = await axios.put<SharedType.Transaction>(`/transactions/${id}`, input)
        return data
    },
})

export function useTransactionApi() {
    const queryClient = useQueryClient()
    const { axios } = useAxiosWithAuth()
    const api = useMemo(() => TransactionApi(axios), [axios])

    const useTransactions = (
        { pageIndex = 0, pageSize = 50 }: { pageIndex?: number; pageSize?: number },
        options?: Omit<
            UseQueryOptions<
                SharedType.TransactionsResponse,
                unknown,
                SharedType.TransactionsResponse,
                any[]
            >,
            'queryKey' | 'queryFn' | 'staleTime'
        >
    ) =>
        useQuery(['transactions', pageIndex, pageSize], () => api.getAll(pageIndex, pageSize), {
            staleTime: 60_000,
            ...options,
        })

    const useTransaction = (
        id: Transaction['id'],
        options?: Omit<
            UseQueryOptions<
                SharedType.TransactionWithAccountDetail,
                unknown,
                SharedType.TransactionWithAccountDetail,
                any[]
            >,
            'queryKey' | 'queryFn' | 'staleTime'
        >
    ) => {
        return useQuery(['transactions', id], () => api.get(id), {
            staleTime: 60_000,
            ...options,
        })
    }

    const useUpdateTransaction = (
        options?: UseMutationOptions<SharedType.Transaction, unknown, Record<string, any>>
    ) =>
        useMutation(
            ({ id, data }: { id: SharedType.Transaction['id']; data: Record<string, any> }) =>
                api.update(id, data),
            {
                onSuccess: () => {
                    toast.success('Transaction successfully updated!')
                },
                onError: () => {
                    toast.error('Error updating transaction')
                },
                onSettled: () => {
                    queryClient.invalidateQueries(['transactions'])
                },
                ...options,
            }
        )

    return {
        useTransactions,
        useTransaction,
        useUpdateTransaction,
    }
}
