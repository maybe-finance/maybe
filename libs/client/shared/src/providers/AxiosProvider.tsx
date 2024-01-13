import type { AxiosInstance, AxiosRequestConfig, AxiosResponse } from 'axios'
import type { SharedType } from '@maybe-finance/shared'
import { superjson } from '@maybe-finance/shared'
import { createContext, type PropsWithChildren, useMemo } from 'react'
import Axios from 'axios'

type CreateInstanceOptions = {
    getToken?: () => Promise<string | null>
    axiosOptions?: AxiosRequestConfig
    serialize?: boolean
    deserialize?: boolean
}

export type AxiosContextValue = {
    defaultBaseUrl: string
    axios: AxiosInstance
    createInstance: (options?: CreateInstanceOptions) => AxiosInstance
}

export const AxiosContext = createContext<AxiosContextValue | undefined>(undefined)

// Factory fn to create an instance for ad-hoc request types (e.g. multipart/form-data)
function createInstance(options?: CreateInstanceOptions) {
    const instance = Axios.create(options?.axiosOptions)

    instance.interceptors.request.use(async (config) => {
        if (options?.getToken) {
            const token = await options.getToken()

            if (token) {
                if (config.headers) {
                    config.headers.Authorization = `Bearer ${token}`
                }

                // For local testing convenience
                if (process.env.NODE_ENV === 'development') {
                    ;(window as any).JWT = token
                }
            }
        }

        if (options?.serialize) {
            return { ...config, data: superjson.serialize(config.data) }
        } else {
            return config
        }
    })

    if (options?.deserialize) {
        instance.interceptors.response.use((response: AxiosResponse<SharedType.BaseResponse>) => {
            if (response.data) {
                const payload = response.data

                if ('data' in payload) {
                    return { ...response, data: superjson.deserialize(payload.data) }
                } else {
                    // Don't deserialize an error response
                    return response
                }
            } else {
                // Don't deserialize a No Content response (i.e. 204)
                return response
            }
        })
    }

    return instance
}

/**
 * Injects the Auth0 access token into every axios request
 *
 * @see https://github.com/auth0/auth0-react/issues/266#issuecomment-919222402
 */
export function AxiosProvider({ children }: PropsWithChildren) {
    // Rather than storing access token in localStorage (insecure), we use this method to retrieve it prior to making API calls
    const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3333'

    // Expose a default instance with auth, superjson, headers
    const defaultInstance = useMemo(() => {
        const defaultHeaders = {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Credentials': true,
        }
        return createInstance({
            axiosOptions: {
                baseURL: `${API_URL}/v1`,
                headers: defaultHeaders,
                withCredentials: true,
            },
            serialize: true,
            deserialize: true,
        })
    }, [API_URL])

    return (
        <AxiosContext.Provider
            value={{
                defaultBaseUrl: `${API_URL}/v1`,
                axios: defaultInstance,
                createInstance,
            }}
        >
            {children}
        </AxiosContext.Provider>
    )
}
