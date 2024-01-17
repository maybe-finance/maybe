import { useMemo } from 'react'
import toast from 'react-hot-toast'
import { useAxiosWithAuth } from '../hooks/useAxiosWithAuth'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import type { SharedType } from '@maybe-finance/shared'
import { invalidateAccountQueries } from '../utils'
import type { AxiosInstance } from 'axios'
import type { TellerTypes } from '@maybe-finance/teller-api'

type TellerInstitution = {
    name: string
    id: string
}

const TellerApi = (axios: AxiosInstance) => ({
    async handleEnrollment(input: {
        institution: TellerInstitution
        enrollment: TellerTypes.Enrollment
    }) {
        const { data } = await axios.post<SharedType.AccountConnection>(
            '/teller/handle-enrollment',
            input
        )
        return data
    },
})

export function useTellerApi() {
    const queryClient = useQueryClient()
    const { axios } = useAxiosWithAuth()
    const api = useMemo(() => TellerApi(axios), [axios])

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

    const useHandleEnrollment = () =>
        useMutation(api.handleEnrollment, {
            onSuccess: (_connection) => {
                addConnectionToState(_connection)
                toast.success(`Account connection added!`)
            },
            onSettled: () => {
                invalidateAccountQueries(queryClient, false)
            },
        })

    return {
        useHandleEnrollment,
    }
}
