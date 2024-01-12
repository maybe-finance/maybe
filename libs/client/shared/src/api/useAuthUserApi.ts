import type { SharedType } from '@maybe-finance/shared'
import type { AxiosInstance } from 'axios'
import { useMemo } from 'react'
import { useQuery } from '@tanstack/react-query'
import { useAxiosWithAuth } from '../hooks/useAxiosWithAuth'

const AuthUserApi = (axios: AxiosInstance) => ({
    async getByEmail(email: string) {
        const { data } = await axios.get<SharedType.AuthUser>(`/auth-users/${email}`)
        return data
    },
})

const staleTimes = {
    user: 30_000,
    netWorth: 30_000,
    insights: 30_000,
}

export function useAuthUserApi() {
    const { axios } = useAxiosWithAuth()
    const api = useMemo(() => AuthUserApi(axios), [axios])

    const useGetByEmail = (email: string) =>
        useQuery(['auth-users', email], () => api.getByEmail(email), { staleTime: staleTimes.user })

    return {
        useGetByEmail,
    }
}
