import type { AxiosInstance } from 'axios'
import type { Account } from '@prisma/client'
import type { SharedType } from '@maybe-finance/shared'
import type {
    UseInfiniteQueryOptions,
    UseMutationOptions,
    UseQueryOptions,
} from '@tanstack/react-query'

import { useMemo } from 'react'
import sumBy from 'lodash/sumBy'
import toast from 'react-hot-toast'
import { useInfiniteQuery, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAxiosWithAuth, useIntercom } from '..'
import { invalidateAccountQueries } from '../utils'

const AccountApi = (axios: AxiosInstance) => ({
    async getAccounts() {
        const { data } = await axios.get<SharedType.AccountsResponse>('/accounts')
        return data
    },

    async get(id: SharedType.Account['id']): Promise<SharedType.AccountDetail> {
        const { data } = await axios.get<SharedType.AccountDetail>(`/accounts/${id}`)
        return data
    },

    async create(input: Record<string, any>) {
        const { data } = await axios.post<SharedType.Account>('/accounts', input)
        return data
    },

    async update(id: SharedType.Account['id'], input: Record<string, any>) {
        const { data } = await axios.put<SharedType.Account>(`/accounts/${id}`, input)
        return data
    },

    async delete(id: SharedType.Account['id']) {
        const { data } = await axios.delete<SharedType.Account>(`/accounts/${id}`)
        return data
    },

    async getBalances(
        id: SharedType.Account['id'],
        start: string,
        end: string
    ): Promise<SharedType.AccountBalanceResponse> {
        const { data } = await axios.get<SharedType.AccountBalanceResponse>(
            `/accounts/${id}/balances`,
            { params: { start, end } }
        )
        return data
    },

    async getReturns(
        id: SharedType.Account['id'],
        start: string,
        end: string,
        compare: string[]
    ): Promise<SharedType.AccountReturnResponse> {
        const { data } = await axios.get<SharedType.AccountReturnResponse>(
            `/accounts/${id}/returns`,
            { params: { start, end, compare: compare.length ? compare.join(',') : undefined } }
        )
        return data
    },

    async getTransactions(
        id: SharedType.Account['id'],
        page: number
    ): Promise<SharedType.AccountTransactionResponse> {
        const { data } = await axios.get<SharedType.AccountTransactionResponse>(
            `/accounts/${id}/transactions`,
            { params: { page } }
        )
        return data
    },

    async getHoldings(
        id: SharedType.Account['id'],
        page: number
    ): Promise<SharedType.AccountHoldingResponse> {
        const { data } = await axios.get<SharedType.AccountHoldingResponse>(
            `/accounts/${id}/holdings`,
            { params: { page } }
        )
        return data
    },

    async getInvestmentTransactions(
        id: SharedType.Account['id'],
        page: number,
        start?: string,
        end?: string,
        category?: SharedType.InvestmentTransactionCategory
    ): Promise<SharedType.AccountInvestmentTransactionResponse> {
        const { data } = await axios.get<SharedType.AccountInvestmentTransactionResponse>(
            `/accounts/${id}/investment-transactions`,
            { params: { page, start, end, category } }
        )
        return data
    },

    async getInsights(id: SharedType.Account['id']): Promise<SharedType.AccountInsights> {
        const { data } = await axios.get<SharedType.AccountInsights>(`/accounts/${id}/insights`)
        return data
    },

    async getRollup(start: string, end: string): Promise<SharedType.AccountRollup> {
        const { data } = await axios.get<SharedType.AccountRollup>(`/account-rollup`, {
            params: { start, end },
        })
        return data
    },

    async sync(id: SharedType.Account['id']) {
        const { data } = await axios.post<SharedType.Account>(`/accounts/${id}/sync`)
        return data
    },
})

const staleTimes = {
    accounts: 30_000,
    balances: 30_000,
    rollup: 30_000,
    insights: 30_000,
    returns: 60_000,
    // Transactions and holdings shouldn't update nearly as often (limited user-driven changes)
    transactions: 60_000,
    holdings: 60_000,
    investmentTransactions: 60_000,
}

export function useAccountApi() {
    const queryClient = useQueryClient()
    const { axios } = useAxiosWithAuth()
    const api = useMemo(() => AccountApi(axios), [axios])
    const { update: updateIntercom } = useIntercom()

    const useAccounts = (
        options?: Omit<
            UseQueryOptions<
                SharedType.AccountsResponse,
                unknown,
                SharedType.AccountsResponse,
                string[]
            >,
            'queryKey' | 'queryFn' | 'staleTime'
        >
    ) =>
        useQuery(['accounts'], api.getAccounts, {
            staleTime: staleTimes.accounts,
            onSuccess: (...args) => {
                if (options?.onSuccess) options.onSuccess(...args)

                const [{ accounts, connections }] = args
                updateIntercom({
                    'Manual Accounts': accounts.length,
                    'Connected Accounts': sumBy(connections, (c) => c.accounts.length),
                    Connections: connections.length,
                })
            },
            ...options,
        })

    const useAccount = (
        id: Account['id'],
        options?: Omit<
            UseQueryOptions<SharedType.AccountDetail, unknown, SharedType.AccountDetail, any[]>,
            'queryKey' | 'queryFn' | 'staleTime'
        >
    ) => {
        return useQuery(['accounts', id], () => api.get(id), {
            staleTime: staleTimes.accounts,
            ...options,
        })
    }

    const useCreateAccount = (
        options?: UseMutationOptions<SharedType.Account, unknown, Record<string, any>>
    ) =>
        useMutation(api.create, {
            onSuccess: () => {
                toast.success('Account successfully added!')
            },
            onError: () => {
                toast.error('Error adding account')
            },
            onSettled: () => {
                invalidateAccountQueries(queryClient)
            },
            ...options,
        })

    const useUpdateAccount = (
        options?: UseMutationOptions<SharedType.Account, unknown, Record<string, any>>
    ) =>
        useMutation(
            ({ id, data }: { id: SharedType.Account['id']; data: Record<string, any> }) =>
                api.update(id, data),
            {
                onSuccess: () => {
                    toast.success('Account successfully updated!')
                },
                onError: () => {
                    toast.error('Error updating account')
                },
                onSettled: () => {
                    invalidateAccountQueries(queryClient)
                },
                ...options,
            }
        )

    const useDeleteAccount = () =>
        useMutation(api.delete, {
            onSuccess: (data) => {
                toast.success(`${data.name} deleted!`)
            },
            onError: () => {
                toast.error('Failed to delete account')
            },
            onSettled: () => {
                invalidateAccountQueries(queryClient)
            },
        })

    const useSyncAccount = () =>
        useMutation(api.sync, {
            onSuccess: (data) => {
                toast.success(`${data.name} sync initiated`)
            },
            onError: () => {
                toast.error('Failed to sync account')
            },
            onSettled: () => {
                invalidateAccountQueries(queryClient, false)
            },
        })

    const useAccountBalances = (
        {
            id,
            start,
            end,
        }: {
            id: Account['id']
        } & SharedType.DateRange,
        options?: Omit<
            UseQueryOptions<
                SharedType.AccountBalanceResponse,
                unknown,
                SharedType.AccountBalanceResponse,
                any[]
            >,
            'queryKey' | 'queryFn' | 'staleTime'
        >
    ) => {
        return useQuery(
            ['accounts', id, 'balances', { start, end }],
            () => api.getBalances(id, start, end),
            { staleTime: staleTimes.balances, ...options }
        )
    }

    const useAccountReturns = (
        {
            id,
            start,
            end,
            compare,
        }: {
            id: Account['id']
            compare: string[]
        } & SharedType.DateRange,
        options?: Omit<
            UseQueryOptions<
                SharedType.AccountReturnResponse,
                unknown,
                SharedType.AccountReturnResponse,
                any[]
            >,
            'queryKey' | 'queryFn' | 'staleTime'
        >
    ) => {
        return useQuery(
            ['accounts', id, 'returns', { start, end, compare }],
            () => api.getReturns(id, start, end, compare),
            { staleTime: staleTimes.returns, ...options }
        )
    }

    const useAccountTransactions = (
        { id }: { id: Account['id'] },
        options?: Omit<
            UseInfiniteQueryOptions<
                SharedType.AccountTransactionResponse,
                unknown,
                SharedType.AccountTransactionResponse,
                SharedType.AccountTransactionResponse,
                any[]
            >,
            'queryKey' | 'queryFn' | 'staleTime'
        >
    ) => {
        return useInfiniteQuery(
            ['accounts', id, 'transactions'],
            ({ pageParam = 0 }) => api.getTransactions(id, pageParam),
            {
                staleTime: staleTimes.transactions,
                ...options,
                getNextPageParam: (lastPage, pages) =>
                    lastPage.totalTransactions >
                    pages.reduce((total, { transactions }) => total + transactions.length, 0)
                        ? pages.length
                        : undefined,
            }
        )
    }

    const useAccountHoldings = (
        {
            id,
        }: {
            id: Account['id']
        },
        options?: Omit<
            UseInfiniteQueryOptions<
                SharedType.AccountHoldingResponse,
                unknown,
                SharedType.AccountHoldingResponse,
                SharedType.AccountHoldingResponse,
                any[]
            >,
            'queryKey' | 'queryFn' | 'staleTime'
        >
    ) => {
        return useInfiniteQuery(
            ['accounts', id, 'holdings'],
            ({ pageParam = 0 }) => api.getHoldings(id, pageParam),
            {
                staleTime: staleTimes.holdings,
                ...options,
                getNextPageParam: (lastPage, pages) =>
                    lastPage.totalHoldings >
                    pages.reduce((total, { holdings }) => total + holdings.length, 0)
                        ? pages.length
                        : undefined,
            }
        )
    }

    const useAccountInvestmentTransactions = (
        {
            id,
            start,
            end,
            category,
        }: {
            id: Account['id']
            category?: SharedType.InvestmentTransactionCategory
        } & Partial<SharedType.DateRange>,
        options?: Omit<
            UseInfiniteQueryOptions<
                SharedType.AccountInvestmentTransactionResponse,
                unknown,
                SharedType.AccountInvestmentTransactionResponse,
                SharedType.AccountInvestmentTransactionResponse,
                any[]
            >,
            'queryKey' | 'queryFn' | 'staleTime'
        >
    ) => {
        return useInfiniteQuery(
            ['accounts', id, 'investmentTransactions', { start, end, category }],
            ({ pageParam = 0 }) =>
                api.getInvestmentTransactions(id, pageParam, start, end, category),
            {
                staleTime: staleTimes.investmentTransactions,
                ...options,
                getNextPageParam: (lastPage, pages) =>
                    lastPage.totalInvestmentTransactions >
                    pages.reduce(
                        (total, { investmentTransactions }) =>
                            total + investmentTransactions.length,
                        0
                    )
                        ? pages.length
                        : undefined,
            }
        )
    }

    const useAccountRollup = (
        { start, end }: SharedType.DateRange,
        options?: Omit<
            UseQueryOptions<SharedType.AccountRollup, unknown, SharedType.AccountRollup, any[]>,
            'queryKey' | 'queryFn' | 'staleTime'
        >
    ) =>
        useQuery(['accounts', 'rollup', { start, end }], () => api.getRollup(start, end), {
            staleTime: staleTimes.rollup,
            ...options,
        })

    const useAccountInsights = (
        id: Account['id'],
        options?: Omit<
            UseQueryOptions<SharedType.AccountInsights, unknown, SharedType.AccountInsights, any[]>,
            'queryKey' | 'queryFn' | 'staleTime'
        >
    ) =>
        useQuery(['accounts', id, 'insights'], () => api.getInsights(id), {
            staleTime: staleTimes.insights,
            ...options,
        })

    return {
        useAccounts,
        useAccount,
        useCreateAccount,
        useUpdateAccount,
        useDeleteAccount,
        useSyncAccount,
        useAccountBalances,
        useAccountReturns,
        useAccountTransactions,
        useAccountHoldings,
        useAccountInvestmentTransactions,
        useAccountRollup,
        useAccountInsights,
    }
}
