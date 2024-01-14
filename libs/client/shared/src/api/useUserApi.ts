import type { UseMutationOptions, UseQueryOptions } from '@tanstack/react-query'
import type { SharedType } from '@maybe-finance/shared'
import type { AxiosInstance } from 'axios'
import * as Sentry from '@sentry/react'
import { useMemo } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'react-hot-toast'
import { DateTime } from 'luxon'
import { useAxiosWithAuth } from '../hooks/useAxiosWithAuth'

const UserApi = (axios: AxiosInstance) => ({
    async getNetWorthSeries(start: string, end: string) {
        const { data } = await axios.get<SharedType.NetWorthTimeSeriesResponse>(
            `/users/net-worth`,
            {
                params: { start, end },
            }
        )
        return data
    },

    async getInsights() {
        const { data } = await axios.get<SharedType.UserInsights>(`/users/insights`)
        return data
    },

    async getNetWorth(date: string) {
        const { data } = await axios.get<SharedType.NetWorthTimeSeriesData>(
            `/users/net-worth/${date}`
        )
        return data
    },

    async update(userData: SharedType.UpdateUser) {
        const { data } = await axios.put<SharedType.User>('/users', userData)
        return data
    },

    async get() {
        const { data } = await axios.get<SharedType.User>('/users')
        return data
    },

    async delete() {
        return axios.delete('/users', { data: { confirm: true } })
    },

    async getOnboarding(flow: SharedType.OnboardingFlow) {
        const { data } = await axios.get<SharedType.OnboardingResponse>(`/users/onboarding/${flow}`)
        return data
    },

    async updateOnboarding(input: {
        flow: SharedType.OnboardingFlow
        updates: { key: string; markedComplete: boolean }[]
        markedComplete?: boolean
    }) {
        const { data } = await axios.put<SharedType.User>('/users/onboarding', input)
        return data
    },

    async getAuthProfile() {
        const { data } = await axios.get<SharedType.AuthUser>('/users/auth-profile')
        return data
    },

    async getSubscription() {
        const { data } = await axios.get<SharedType.UserSubscription>('/users/subscription')
        return data
    },

    async changePassword(newPassword: SharedType.PasswordReset) {
        const { data } = await axios.put<
            SharedType.PasswordReset,
            SharedType.ApiResponse<{ success: boolean; error?: string }>
        >('/users/change-password', newPassword)
        return data
    },

    async resendEmailVerification(authId?: string) {
        const { data } = await axios.post<{ success: boolean }>(
            '/users/resend-verification-email',
            { authId }
        )

        return data
    },

    async createCheckoutSession(plan: string) {
        const { data } = await axios.post<{ url: string }>('/users/checkout-session', { plan })

        return data
    },

    async createCustomerPortalSession(plan: string) {
        const { data } = await axios.post<{ url: string }>('/users/customer-portal-session', {
            plan,
        })

        return data
    },

    async getMemberCardDetails(memberId?: string) {
        const { data } = await axios.get<SharedType.UserMemberCardDetails>(
            `/users/card/${memberId ?? ''}`
        )

        return data
    },
})

const staleTimes = {
    user: 30_000,
    netWorth: 30_000,
    insights: 30_000,
}

export function useUserApi() {
    const queryClient = useQueryClient()
    const { axios } = useAxiosWithAuth()
    const api = useMemo(() => UserApi(axios), [axios])

    const useNetWorthSeries = (
        { start, end }: { start: string; end: string },
        options?: Omit<
            UseQueryOptions<
                SharedType.NetWorthTimeSeriesResponse,
                unknown,
                SharedType.NetWorthTimeSeriesResponse,
                any[]
            >,
            'queryKey' | 'queryFn'
        >
    ) =>
        useQuery(
            ['users', 'net-worth', 'series', { start, end }],
            () => api.getNetWorthSeries(start, end),
            { staleTime: staleTimes.netWorth, ...options }
        )

    const useCurrentNetWorth = (date: string = DateTime.local().toISODate()) =>
        useQuery(['users', 'net-worth', 'current', { date }], () => api.getNetWorth(date), {
            staleTime: staleTimes.netWorth,
        })

    const useInsights = () =>
        useQuery(['users', 'insights'], () => api.getInsights(), {
            staleTime: staleTimes.insights,
        })

    const useProfile = (
        options?: Omit<
            UseQueryOptions<SharedType.User, unknown, SharedType.User, any[]>,
            'queryKey' | 'queryFn'
        >
    ) =>
        useQuery(['users'], api.get, {
            staleTime: staleTimes.user,
            ...options,
        })

    const useOnboarding = (
        flow: SharedType.OnboardingFlow,
        options?: Omit<
            UseQueryOptions<
                SharedType.OnboardingResponse,
                unknown,
                SharedType.OnboardingResponse,
                any[]
            >,
            'queryKey' | 'queryFn'
        >
    ) => useQuery(['users', 'onboarding', flow], () => api.getOnboarding(flow), options)

    const useUpdateOnboarding = (
        options?: UseMutationOptions<
            SharedType.User,
            unknown,
            {
                flow: SharedType.OnboardingFlow
                updates: { key: string; markedComplete: boolean }[]
                markedComplete?: boolean
            }
        >
    ) =>
        useMutation(api.updateOnboarding, {
            onSettled: () => queryClient.invalidateQueries(['users', 'onboarding']),
            ...options,
        })

    const useUpdateProfile = (
        options?: UseMutationOptions<SharedType.User, unknown, SharedType.UpdateUser>
    ) =>
        useMutation(api.update, {
            onSuccess: () => {
                toast.success(`Updated user!`)
            },
            onError: () => {
                toast.error('Error updating user')
            },
            onSettled: () => {
                queryClient.invalidateQueries(['users'])
            },
            ...options,
        })

    const useAuthProfile = (
        options?: Omit<
            UseQueryOptions<SharedType.AuthUser, unknown, SharedType.AuthUser, any[]>,
            'queryKey' | 'queryFn'
        >
    ) =>
        useQuery(['auth-profile'], api.getAuthProfile, {
            staleTime: staleTimes.user,
            ...options,
        })

    const useSubscription = (
        options?: Omit<UseQueryOptions<SharedType.UserSubscription>, 'queryKey' | 'queryFn'>
    ) => useQuery(['users', 'subscription'], api.getSubscription, options)

    const useChangePassword = () =>
        useMutation(api.changePassword, {
            onSuccess: () => {
                toast.success('Password reset successfully')
            },
            onError: (err) => {
                toast.error(typeof err === 'string' ? err : 'Could not reset password')
            },
            onSettled: () => {
                queryClient.invalidateQueries(['users'])
            },
        })

    const useResendEmailVerification = (
        options?: UseMutationOptions<{ success: boolean } | undefined, unknown, string | undefined>
    ) =>
        useMutation(api.resendEmailVerification, {
            onError: () => {
                toast.error(
                    'Hmm... Something went wrong sending the verification email.  Please contact us for additional help.'
                )
            },
            ...options,
        })

    const useCreateCheckoutSession = (
        options?: UseMutationOptions<{ url: string }, unknown, string>
    ) =>
        useMutation(api.createCheckoutSession, {
            onError: (err) => {
                Sentry.captureException(err)
                toast.error('Error creating checkout session')
            },
            ...options,
        })

    const useCreateCustomerPortalSession = (
        options?: UseMutationOptions<{ url: string }, unknown, string>
    ) =>
        useMutation(api.createCustomerPortalSession, {
            onError: (err) => {
                Sentry.captureException(err)
                toast.error('Error creating customer portal session')
            },
            ...options,
        })

    const useMemberCardDetails = (
        memberId?: string,
        options?: Omit<UseQueryOptions<SharedType.UserMemberCardDetails>, 'queryKey' | 'queryFn'>
    ) =>
        useQuery(
            ['users', 'card', memberId ?? 'current'],
            () => api.getMemberCardDetails(memberId),
            options
        )

    const useDelete = (options?: UseMutationOptions<{}, unknown, any>) =>
        useMutation(api.delete, options)

    return {
        useNetWorthSeries,
        useInsights,
        useCurrentNetWorth,
        useProfile,
        useUpdateProfile,
        useAuthProfile,
        useSubscription,
        useChangePassword,
        useResendEmailVerification,
        useCreateCheckoutSession,
        useCreateCustomerPortalSession,
        useMemberCardDetails,
        useOnboarding,
        useUpdateOnboarding,
        useDelete,
    }
}
