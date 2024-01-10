import { useContext } from 'react'
import { AxiosContext, type AxiosContextValue } from '../providers/AxiosProvider'

export const useAxiosWithAuth: () => AxiosContextValue = () => {
    const axiosInstance = useContext(AxiosContext)

    if (!axiosInstance) {
        throw new Error('Axios provider configured incorrectly')
    }

    return axiosInstance
}
