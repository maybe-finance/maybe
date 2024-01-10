import type { Security } from '@prisma/client'
import type { AxiosInstance } from 'axios'
import type { UseQueryOptions } from '@tanstack/react-query'
import type { SharedType } from '@maybe-finance/shared'
import { useMemo } from 'react'
import { useQuery } from '@tanstack/react-query'
import { useAxiosWithAuth } from '..'

const SecurityApi = (axios: AxiosInstance) => ({
    async getSecurity(id: Security['id']) {
        const { data } = await axios.get<SharedType.SecurityWithPricing>(`/securities/${id}`)
        return data
    },

    async getSecurityDetails(id: Security['id']) {
        const { data } = await axios.get<SharedType.SecurityDetails>(`/securities/${id}/details`)
        return data
    },
})

const staleTimes = {
    security: 30 * 1000, // 30 seconds
    securityDetails: 30 * 1000, // 30 seconds
}

export function useSecurityApi() {
    const { axios } = useAxiosWithAuth()
    const api = useMemo(() => SecurityApi(axios), [axios])

    const useSecurity = (
        id: Security['id'],
        options?: Omit<
            UseQueryOptions<
                SharedType.SecurityWithPricing,
                unknown,
                SharedType.SecurityWithPricing,
                any[]
            >,
            'queryKey' | 'queryFn' | 'staleTime'
        >
    ) => {
        return useQuery(['securities', id], () => api.getSecurity(id), {
            staleTime: staleTimes.security,
            ...options,
        })
    }

    const useSecurityDetails = (
        id: Security['id'],
        options?: Omit<
            UseQueryOptions<SharedType.SecurityDetails, unknown, SharedType.SecurityDetails, any[]>,
            'queryKey' | 'queryFn' | 'staleTime'
        >
    ) => {
        return useQuery(['securities', id, 'details'], () => api.getSecurityDetails(id), {
            staleTime: staleTimes.securityDetails,
            ...options,
        })
    }

    return {
        useSecurity,
        useSecurityDetails,
    }
}
