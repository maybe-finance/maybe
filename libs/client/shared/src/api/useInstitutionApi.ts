import type { UseInfiniteQueryOptions } from '@tanstack/react-query'
import type { AxiosInstance } from 'axios'
import type { SharedType } from '@maybe-finance/shared'
import { useMemo } from 'react'
import { useInfiniteQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import toast from 'react-hot-toast'
import { useAxiosWithAuth } from '../hooks/useAxiosWithAuth'

const InstitutionApi = (axios: AxiosInstance) => ({
    async getInstitutions(page: number, search?: string) {
        const { data } = await axios.get<SharedType.InstitutionsResponse>('/institutions', {
            params: { page, q: search },
        })
        return data
    },

    async sync() {
        const { data } = await axios.post(`/institutions/sync`)
        return data
    },

    async deduplicate() {
        const { data } = await axios.post(`/institutions/deduplicate`)
        return data
    },
})

const staleTimes = {
    institutions: 5 * 60 * 1000, // 5 minutes
}

export function useInstitutionApi() {
    const queryClient = useQueryClient()
    const { axios } = useAxiosWithAuth()
    const api = useMemo(() => InstitutionApi(axios), [axios])

    const useInstitutions = (
        {
            search,
        }: {
            search?: string
        },
        options?: Omit<
            UseInfiniteQueryOptions<
                SharedType.InstitutionsResponse,
                unknown,
                SharedType.InstitutionsResponse,
                SharedType.InstitutionsResponse,
                any[]
            >,
            'queryKey' | 'queryFn'
        >
    ) => {
        return useInfiniteQuery(
            ['institutions', { search }],
            ({ pageParam = 0 }) => api.getInstitutions(pageParam, search),
            {
                staleTime: staleTimes.institutions,
                ...options,
                getNextPageParam: (lastPage, pages) =>
                    lastPage.totalInstitutions >
                    pages.reduce((total, { institutions }) => total + institutions.length, 0)
                        ? pages.length
                        : undefined,
            }
        )
    }

    const useSyncInstitutions = () =>
        useMutation(api.sync, {
            onSuccess: () => {
                toast.success(`Syncing institutions`)
            },
            onError: () => {
                toast.error('Failed to sync institutions')
            },
            onSettled: () => {
                queryClient.invalidateQueries(['institutions'])
            },
        })

    const useDeduplicateInstitutions = () =>
        useMutation(api.deduplicate, {
            onMutate: () => {
                toast.loading(`Deduplicating institutions`)
            },
            onSuccess: () => {
                toast.success(`Deduplicated institutions`)
            },
            onError: () => {
                toast.error('Failed to deduplicate institutions')
            },
            onSettled: () => {
                queryClient.invalidateQueries(['institutions'])
            },
        })

    return {
        useInstitutions,
        useSyncInstitutions,
        useDeduplicateInstitutions,
    }
}
