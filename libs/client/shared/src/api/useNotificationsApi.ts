import type { AxiosInstance } from 'axios'
import type { UseQueryOptions } from '@tanstack/react-query'
import type { SharedType } from '@maybe-finance/shared'
import { useMemo } from 'react'
import { useMutation, useQueryClient, useQuery } from '@tanstack/react-query'
import { useAxiosWithAuth } from '..'
import toast from 'react-hot-toast'

const NotificationsApi = (axios: AxiosInstance) => ({
    async getConvertKitSubscription() {
        const { data } = await axios.get<{
            isSubscribed: boolean
            subscriber?: SharedType.ConvertKitSubscriber
        }>(`/notifications/convertkit/subscription`)

        return data
    },

    async manageSubscription(action: 'subscribe' | 'unsubscribe') {
        const { data } = await axios.post<SharedType.ConvertKitSubscription>(
            `/notifications/convertkit/${action}`
        )
        return data
    },

    async updateATANotifications(input: Record<string, any>) {
        const { data } = await axios.put<SharedType.User>(`/notifications/ask-the-advisor`, input)
        return data
    },
})

type SubscriptionState = {
    isSubscribed: boolean
    subscriber?: SharedType.ConvertKitSubscriber
}

export function useNotificationsApi() {
    const queryClient = useQueryClient()
    const { axios } = useAxiosWithAuth()
    const api = useMemo(() => NotificationsApi(axios), [axios])

    const useConvertKitSubscriber = (
        options?: Omit<
            UseQueryOptions<
                { isSubscribed: boolean; subscriber?: SharedType.ConvertKitSubscriber },
                unknown,
                { isSubscribed: boolean; subscriber?: SharedType.ConvertKitSubscriber },
                any[]
            >,
            'queryKey' | 'queryFn' | 'staleTime'
        >
    ) => {
        return useQuery(['notifications', 'convertkit'], api.getConvertKitSubscription, {
            staleTime: 30_000,
            ...options,
        })
    }

    const useConvertKit = () =>
        useMutation(api.manageSubscription, {
            onMutate: async (action) => {
                await queryClient.cancelQueries({ queryKey: ['notifications'] })
                const previousSubscription = queryClient.getQueryData<SubscriptionState>([
                    'notifications',
                    'convertkit',
                ])

                // Optimistic update to new state
                queryClient.setQueryData(['notifications', 'convertkit'], () => ({
                    ...previousSubscription,
                    isSubscribed: action === 'subscribe',
                }))

                return { previousSubscription }
            },
            onSuccess: () => {
                toast.success('Newsletter preferences updated!')
            },
            onError: (err, action, ctx) => {
                queryClient.setQueryData(['notifications', 'convertkit'], ctx?.previousSubscription)

                toast.error('Error updating newsletter preferences')
            },
            onSettled: () => {
                queryClient.invalidateQueries(['notifications', 'convertkit'])
            },
        })

    const useUpdateATANotifications = () =>
        useMutation(api.updateATANotifications, {
            onMutate: async (updates) => {
                await queryClient.cancelQueries({ queryKey: ['users'] })

                const previousUser = queryClient.getQueryData<SharedType.User>(['users'])

                // Optimistic update to new state
                queryClient.setQueryData(['users'], () => ({
                    ...previousUser,
                    ...updates,
                }))

                return { previousUser }
            },
            onSuccess: () => {
                toast.success('Ask the Advisor notifications updated!')
            },
            onError: (err, updates, ctx) => {
                queryClient.setQueryData(['users'], ctx?.previousUser)
                toast.error('Error updating ask the advisor preferences')
            },
            onSettled: () => {
                queryClient.invalidateQueries(['users'])
            },
        })

    return {
        useConvertKitSubscriber,
        useConvertKit,
        useUpdateATANotifications,
    }
}
