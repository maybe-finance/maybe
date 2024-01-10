import type { AxiosError, AxiosRequestConfig, AxiosResponse } from 'axios'
import type { PlaidError } from 'plaid'

class MockPlaidError extends Error implements AxiosError {
    isAxiosError = true
    code?: string | undefined
    config: AxiosRequestConfig<any> = {}
    request?: any
    response?: AxiosResponse<any, any>
    toJSON = () => ({})

    constructor(error: PlaidError, status: number) {
        super(error.error_message)

        this.response = {
            status,
            statusText: 'ERROR',
            data: error,
            config: {},
            headers: {},
        }
    }
}

export function mockPlaidError(error: PlaidError, status = 400) {
    return new MockPlaidError(error, status)
}

export function axiosSuccess<T>(data: T) {
    return {
        status: 200,
        statusText: '200',
        headers: {},
        config: {},
        data,
    }
}

export function axios400Error<T>(data: T) {
    return {
        config: {},
        response: {
            status: 400,
            statusText: '400',
            headers: {},
            config: {},
            data,
        },
        isAxiosError: true,
    }
}
