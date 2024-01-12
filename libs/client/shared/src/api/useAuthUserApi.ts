import type { UseMutationOptions, UseQueryOptions } from '@tanstack/react-query'
import type { SharedType } from '@maybe-finance/shared'
import type { AxiosInstance } from 'axios'
import Axios from 'axios'
import * as Sentry from '@sentry/react'
import { useMemo } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'react-hot-toast'
import { DateTime } from 'luxon'
import { useAxiosWithAuth } from '../hooks/useAxiosWithAuth'

const AuthUserApi = (axios: AxiosInstance) => ({
    async getByEmail(email: string) {
        const { data } = await axios.get<SharedType.AuthUser>(`/auth-users/${email}`)
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

    async updateOnboarding(input: {
        flow: SharedType.OnboardingFlow
        updates: { key: string; markedComplete: boolean }[]
        markedComplete?: boolean
    }) {
        const { data } = await axios.put<SharedType.User>('/users/onboarding', input)
        return data
    },

    async changePassword(newPassword: SharedType.PasswordReset) {
        const { data } = await axios.put<
            SharedType.PasswordReset,
            SharedType.ApiResponse<{ success: boolean; error?: string }>
        >('/users/change-password', newPassword)
        return data
    },
})

const staleTimes = {
    user: 30_000,
    netWorth: 30_000,
    insights: 30_000,
}

export function useAuthUserApi() {
    const queryClient = useQueryClient()
    const { axios } = useAxiosWithAuth()
    const api = useMemo(() => AuthUserApi(axios), [axios])

    const useGetByEmail = (email: string) =>
        useQuery(['auth-users', email], () => api.getByEmail(email), { staleTime: staleTimes.user })

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

    const useDelete = (options?: UseMutationOptions<{}, unknown, any>) =>
        useMutation(api.delete, options)

    return {
        useGetByEmail,
        useUpdateOnboarding,
        useDelete,
    }
}
