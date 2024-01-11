import type { UseMutationOptions, UseQueryOptions } from '@tanstack/react-query'
import type { SharedType } from '@maybe-finance/shared'
import type { Auth0ContextInterface } from '@auth0/auth0-react'
import type { AxiosInstance } from 'axios'
import Axios from 'axios'
import type { Agreement } from '@prisma/client'
import * as Sentry from '@sentry/react'
import { useMemo } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'react-hot-toast'
import { DateTime } from 'luxon'
import { useAxiosWithAuth } from '../hooks/useAxiosWithAuth'
import { useAuth0 } from '@auth0/auth0-react'

const UserApi = (
    axios: AxiosInstance,
    auth0: Auth0ContextInterface<SharedType.Auth0ReactUser>
) => ({
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

    async getAuth0Profile() {
        const { data } = await axios.get<SharedType.Auth0Profile>('/users/auth0-profile')
        return data
    },

    async updateAuth0Profile(newProfile: SharedType.UpdateAuth0User) {
        const { data } = await axios.put<
            SharedType.Auth0User,
            SharedType.ApiResponse<SharedType.Auth0User>
        >('/users/auth0-profile', newProfile)
        return data
    },

    async getSubscription() {
        const { data } = await axios.get<SharedType.UserSubscription>('/users/subscription')
        return data
    },

    async toggleMFA(desiredMFAState: 'enabled' | 'disabled'): Promise<{
        actualMFAState: 'enabled' | 'disabled'
        desiredMFAState: 'enabled' | 'disabled'
        mfaRegistrationComplete: boolean
    }> {
        const audience = process.env.NEXT_PUBLIC_AUTH0_AUDIENCE || 'https://maybe-finance-api/v1'

        await axios.put<SharedType.Auth0User, SharedType.ApiResponse<SharedType.Auth0User>>(
            '/users/auth0-profile',
            {
                user_metadata: { enrolled_mfa: desiredMFAState === 'enabled' ? true : false },
            }
        )

        // If the user is enabling MFA, prompt them to set it up immediately
        if (desiredMFAState === 'enabled') {
            await auth0.loginWithPopup(
                {
                    authorizationParams: {
                        connection: 'Username-Password-Authentication',
                        screen_hint: 'show-form-only',
                        display: 'page',
                        audience,
                    },
                },
                { timeoutInSeconds: 360 }
            )
        }

        const currentIdTokenMFAState = auth0.user?.['https://maybe.co/user-metadata']?.enrolled_mfa
            ? 'enabled'
            : 'disabled'

        // If the ID token is the same as the user's intended MFA state, that means they successfully
        // completed the flow.  If not, they closed the popup early.
        return {
            actualMFAState: currentIdTokenMFAState,
            desiredMFAState,
            mfaRegistrationComplete:
                currentIdTokenMFAState === desiredMFAState || desiredMFAState === 'disabled',
        }
    },

    async changePassword(newPassword: SharedType.PasswordReset) {
        const { data } = await axios.put<
            SharedType.PasswordReset,
            SharedType.ApiResponse<{ success: boolean; error?: string }>
        >('/users/change-password', newPassword)
        return data
    },

    async linkAccounts({ secondaryJWT, secondaryProvider }: SharedType.LinkAccounts) {
        try {
            const { data } = await axios.post<
                SharedType.LinkAccounts,
                SharedType.ApiResponse<SharedType.Auth0User>
            >('/users/link-accounts', { secondaryJWT, secondaryProvider })
            return data
        } catch (err) {
            if (Axios.isAxiosError(err)) {
                const message = err.response?.data?.errors?.[0]?.title
                throw new Error(message ?? 'Something went wrong')
            }

            throw err
        }
    },

    async unlinkAccount(unlinkData: SharedType.UnlinkAccount) {
        const { data } = await axios.post<
            SharedType.UnlinkAccount,
            SharedType.ApiResponse<SharedType.Auth0User>
        >('/users/unlink-account', unlinkData)

        return data
    },

    async resendEmailVerification(auth0Id?: string) {
        const { data } = await axios.post<{ success: boolean }>(
            '/users/resend-verification-email',
            { auth0Id }
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

    async getNewestAgreements(type: 'public' | 'user') {
        const { data } = await axios.get('/users/agreements/newest', { params: { type } })
        return data
    },

    async signAgreements(input: Agreement['id'][]) {
        const { data } = await axios.post('/users/agreements/sign', { agreementIds: input })
        return data
    },

    // Dev, Admin only (see AMA dev menu)
    async sendAgreementUpdateEmails() {
        const { data } = await axios.post('/users/agreements/notify-email')
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
    const auth0 = useAuth0()
    const api = useMemo(() => UserApi(axios, auth0), [axios, auth0])

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

    const useAuth0Profile = (
        options?: Omit<UseQueryOptions<SharedType.Auth0Profile>, 'queryKey' | 'queryFn'>
    ) => useQuery(['users', 'auth0-profile'], api.getAuth0Profile, options)

    const useUpdateAuth0Profile = (
        options?: UseMutationOptions<
            SharedType.Auth0User | undefined,
            unknown,
            SharedType.UpdateAuth0User
        >
    ) =>
        useMutation(api.updateAuth0Profile, {
            onSettled() {
                queryClient.invalidateQueries(['users', 'auth0-profile'])
            },
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

    const useLinkAccounts = (
        options?: UseMutationOptions<
            SharedType.Auth0User | undefined,
            unknown,
            SharedType.LinkAccounts
        >
    ) => useMutation(api.linkAccounts, options)

    const useUnlinkAccount = (
        options?: UseMutationOptions<
            SharedType.Auth0User | undefined,
            unknown,
            SharedType.UnlinkAccount
        >
    ) =>
        useMutation(api.unlinkAccount, {
            onSuccess: () => {
                toast.success('Account unlinked!')
                queryClient.invalidateQueries(['users'])
            },
            onError: (err) => {
                Sentry.captureException(err)
                toast.error('Error unlinking user account')
            },
            ...options,
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

    const useSignAgreements = (options?: UseMutationOptions<Agreement['id'][], unknown, any>) =>
        useMutation(api.signAgreements, {
            onSuccess: () => {
                queryClient.invalidateQueries(['users'])
            },
            onError: (err) => {
                Sentry.captureException(err)
                toast.error(
                    'Something went wrong while acknowledging agreements.  Please try again.'
                )
            },
            ...options,
        })

    const useSendAgreementsEmail = (options?: UseMutationOptions<any, unknown, any>) =>
        useMutation(api.sendAgreementUpdateEmails, {
            onSuccess: (data) => {
                toast.success(`Sent ${data.updatedAgreementCount} emails`)
                queryClient.invalidateQueries(['users'])
            },
            onError: (err) => {
                Sentry.captureException(err)
                toast.error('Something went wrong while sending agreement update emails.')
            },
            ...options,
        })

    const useNewestAgreements = (
        type: 'public' | 'user',
        options?: Omit<UseQueryOptions<SharedType.AgreementWithUrl[]>, 'queryKey' | 'queryFn'>
    ) => useQuery(['users', 'agreements', 'newest'], () => api.getNewestAgreements(type), options)

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
        useAuth0Profile,
        useUpdateAuth0Profile,
        useSubscription,
        useChangePassword,
        useLinkAccounts,
        useUnlinkAccount,
        useResendEmailVerification,
        useCreateCheckoutSession,
        useCreateCustomerPortalSession,
        useSignAgreements,
        useSendAgreementsEmail,
        useNewestAgreements,
        useMemberCardDetails,
        useOnboarding,
        useUpdateOnboarding,
        useDelete,
    }
}
