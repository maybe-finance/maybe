import { useMemo } from 'react'
import type { AxiosInstance } from 'axios'
import { useMutation } from '@tanstack/react-query'
import { useAxiosWithAuth } from '../hooks/useAxiosWithAuth'

const FinicityApi = (axios: AxiosInstance) => ({
    async generateConnectUrl(institutionId: string) {
        const { data } = await axios.post<{ link: string }>('/finicity/connect-url', {
            institutionId,
        })
        return data.link
    },
})

export function useFinicityApi() {
    const { axios } = useAxiosWithAuth()
    const api = useMemo(() => FinicityApi(axios), [axios])

    const useGenerateConnectUrl = () => useMutation(api.generateConnectUrl)

    return { useGenerateConnectUrl }
}
