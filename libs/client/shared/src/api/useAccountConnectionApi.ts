import type { SharedType } from '@maybe-finance/shared'
import type { AxiosInstance } from 'axios'
import type { UseMutationOptions } from '@tanstack/react-query'
import { useMemo } from 'react'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { toast } from 'react-hot-toast'
import { useAxiosWithAuth } from '../hooks/useAxiosWithAuth'
import { invalidateAccountQueries } from '../utils'

const AccountConnectionApi = (axios: AxiosInstance) => ({
    async update(id: SharedType.AccountConnection['id'], input: Record<string, any>) {
        const { data } = await axios.put<SharedType.AccountConnection>(`/connections/${id}`, input)
        return data
    },

    async delete(id: SharedType.AccountConnection['id']) {
        const { data } = await axios.delete<SharedType.AccountConnection>(`/connections/${id}`)
        return data
    },

    async deleteAll() {
        const { data } = await axios.delete('/connections')
        return data
    },

    async createPlaidLinkToken(
        id: SharedType.AccountConnection['id'],
        mode: SharedType.PlaidLinkUpdateMode
    ) {
        const { data } = await axios.post<{ token: string }>(
            `/connections/${id}/plaid/link-token?mode=${mode}`
        )
        return data
    },

    async createFinicityFixConnectUrl(id: SharedType.AccountConnection['id']) {
        const { data } = await axios.post<{ link: string }>(
            `/connections/${id}/finicity/fix-connect`
        )
        return data
    },

    async disconnect(id: SharedType.AccountConnection['id']) {
        const { data } = await axios.post<SharedType.AccountConnection>(
            `/connections/${id}/disconnect`
        )
        return data
    },

    async reconnect(id: SharedType.AccountConnection['id']) {
        const { data } = await axios.post<SharedType.AccountConnection>(
            `/connections/${id}/reconnect`
        )
        return data
    },

    async sync(id: SharedType.AccountConnection['id']) {
        const { data } = await axios.post<SharedType.AccountConnection>(`/connections/${id}/sync`)
        return data
    },

    async plaidLinkUpdateCompleted(
        id: SharedType.AccountConnection['id'],
        status: 'success' | 'exit'
    ) {
        const { data } = await axios.post<SharedType.AccountConnection>(
            `/connections/${id}/plaid/link-update-completed`,
            { status }
        )
        return data
    },
})

export function useAccountConnectionApi() {
    const queryClient = useQueryClient()
    const { axios } = useAxiosWithAuth()
    const api = useMemo(() => AccountConnectionApi(axios), [axios])

    const useUpdateConnection = (
        options?: UseMutationOptions<SharedType.AccountConnection, unknown, Record<string, any>>
    ) =>
        useMutation(
            ({ id, data }: { id: SharedType.AccountConnection['id']; data: Record<string, any> }) =>
                api.update(id, data),
            {
                onSettled: () => {
                    invalidateAccountQueries(queryClient)
                },
                ...options,
            }
        )

    const useDeleteConnection = () =>
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

    const useDeleteAllConnections = () =>
        useMutation(api.deleteAll, {
            onSuccess: () => {
                toast.success(`Deleted all connections`)
            },
            onError: () => {
                toast.error('Failed to delete all connections')
            },
            onSettled: () => {
                invalidateAccountQueries(queryClient)
            },
        })

    const useCreatePlaidLinkToken = (mode: SharedType.PlaidLinkUpdateMode) =>
        useMutation((id: SharedType.AccountConnection['id']) => api.createPlaidLinkToken(id, mode))

    const useCreateFinicityFixConnectUrl = (
        options?: UseMutationOptions<{ link: string }, unknown, number, unknown>
    ) => useMutation(api.createFinicityFixConnectUrl, options)

    const useDisconnectConnection = () =>
        useMutation(api.disconnect, {
            onSuccess: (data) => {
                toast.success(`${data.name} disconnected`)
            },
            onError: () => {
                toast.error('Failed to disconnect account')
            },
            onSettled: () => {
                invalidateAccountQueries(queryClient)
            },
        })

    const useReconnectConnection = () =>
        useMutation(api.reconnect, {
            onSuccess: (data) => {
                toast.success(`${data.name} reconnected!`)
            },
            onError: () => {
                toast.error('Failed to reconnect account')
            },
            onSettled: () => {
                invalidateAccountQueries(queryClient)
            },
        })

    const useSyncConnection = () =>
        useMutation(api.sync, {
            onSuccess: (connection) => {
                // update accounts cache immediately
                queryClient.setQueryData(
                    ['accounts'],
                    (
                        prev: SharedType.AccountsResponse = {
                            accounts: [],
                            connections: [],
                        }
                    ) => {
                        const { connections, ...other } = prev
                        return {
                            ...other,
                            connections: connections.map((c) =>
                                c.id === connection.id ? { ...c, ...connection } : c
                            ),
                        }
                    }
                )
            },
            onSettled: () => {
                invalidateAccountQueries(queryClient, false)
            },
        })

    const usePlaidLinkUpdateCompleted = (id: SharedType.AccountConnection['id']) =>
        useMutation((status: 'success' | 'exit') => api.plaidLinkUpdateCompleted(id, status), {
            onSettled: () => {
                invalidateAccountQueries(queryClient, false)
            },
        })

    return {
        useUpdateConnection,
        useDeleteConnection,
        useDeleteAllConnections,
        useCreatePlaidLinkToken,
        useCreateFinicityFixConnectUrl,
        useReconnectConnection,
        useDisconnectConnection,
        useSyncConnection,
        usePlaidLinkUpdateCompleted,
    }
}
