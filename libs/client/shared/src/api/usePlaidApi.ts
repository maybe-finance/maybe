import type { UseQueryOptions } from '@tanstack/react-query'
import type { SharedType } from '@maybe-finance/shared'
import type { AxiosInstance } from 'axios'
import { useMemo } from 'react'
import toast from 'react-hot-toast'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAxiosWithAuth } from '../hooks/useAxiosWithAuth'
import { invalidateAccountQueries } from '../utils'

const PlaidApi = (axios: AxiosInstance) => ({
    async createLinkToken(input: { institutionId?: string }) {
        const { data } = await axios.post<SharedType.LinkConfig>('/plaid/link-token', input)
        return data
    },

    async getLinkToken() {
        const { data } = await axios.get<SharedType.LinkConfig>('/plaid/link-token')
        return data
    },

    async exchangePublicToken(input: { token: string; institution: any }) {
        const { data } = await axios.post<SharedType.AccountConnection>(
            '/plaid/exchange-public-token',
            input
        )
        return data
    },

    async sandboxQuickAdd() {
        const { data } = await axios.post<SharedType.AccountConnection>('/plaid/sandbox/quick-add')
        return data
    },

    async getPlaidStatus() {
        const { data } = await axios.get('/plaid/status')

        return data
    },
})

export function usePlaidApi() {
    const queryClient = useQueryClient()
    const { axios } = useAxiosWithAuth()
    const api = useMemo(() => PlaidApi(axios), [axios])

    const useCreateLinkToken = () =>
        useMutation(api.createLinkToken, {
            onSuccess: ({ token }) => {
                // Every time token changes, set to localstorage so that OAuth redirects have access to the same token that started the flow (see /oauth route)
                if (window.location.pathname !== '/oauth') {
                    localStorage.setItem('link-token', token)
                }
            },
        })

    const useGetLinkToken = (
        options?: Omit<UseQueryOptions<SharedType.LinkConfig>, 'queryKey' | 'queryFn'>
    ) => useQuery(['plaid', 'link-token'], api.getLinkToken, options)

    const addConnectionToState = (connection: SharedType.AccountConnection) => {
        const accountsData = queryClient.getQueryData<SharedType.AccountsResponse>(['accounts'])
        if (!accountsData)
            queryClient.setQueryData<SharedType.AccountsResponse>(['accounts'], {
                connections: [{ ...connection, accounts: [] }],
                accounts: [],
            })
        else {
            const { connections, ...rest } = accountsData
            queryClient.setQueryData<SharedType.AccountsResponse>(['accounts'], {
                connections: [...connections, { ...connection, accounts: [] }],
                ...rest,
            })
        }
    }

    const useExchangePublicToken = () =>
        useMutation(api.exchangePublicToken, {
            onSuccess: (_connection) => {
                addConnectionToState(_connection)
                toast.success(`Account link initiated!`)
            },
            onSettled: () => {
                invalidateAccountQueries(queryClient, false)
            },
        })

    const useSandboxQuickAdd = () =>
        useMutation(api.sandboxQuickAdd, {
            onSuccess: (_connection) => {
                addConnectionToState(_connection)
                toast.success(`Account link initiated!`)
            },
            onSettled: () => {
                invalidateAccountQueries(queryClient, false)
            },
        })

    const usePlaidStatus = (
        options?: Omit<UseQueryOptions<SharedType.StatusPageResponse>, 'queryKey' | 'queryFn'>
    ) => useQuery(['plaid', 'status'], api.getPlaidStatus, options)

    return {
        useCreateLinkToken,
        useGetLinkToken,
        useExchangePublicToken,
        useSandboxQuickAdd,
        usePlaidStatus,
    }
}
