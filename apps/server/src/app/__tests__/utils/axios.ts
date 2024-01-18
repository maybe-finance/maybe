import type { AxiosResponse } from 'axios'
import type { SharedType } from '@maybe-finance/shared'
import { superjson } from '@maybe-finance/shared'
import Axios from 'axios'
import { encode } from 'next-auth/jwt'

export async function getAxiosClient() {
    const baseUrl = 'http://127.0.0.1:53333/v1'
    const jwt = await encode({
        maxAge: 1 * 24 * 60 * 60,
        secret: process.env.NEXTAUTH_SECRET || 'CHANGE_ME',
        token: {
            sub: '__TEST_USER_ID__',
            user: '__TEST_USER_ID__',
            'https://maybe.co/email': 'REPLACE_THIS',
            firstName: 'REPLACE_THIS',
            lastName: 'REPLACE_THIS',
            name: 'REPLACE_THIS',
        },
    })

    const defaultHeaders = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Credentials': true,
        Authorization: `Bearer ${jwt}`,
    }
    const axiosOptions = {
        baseURL: baseUrl,
        headers: defaultHeaders,
    }

    const axios = Axios.create({
        ...axiosOptions,
        validateStatus: () => true, // Tests should determine whether status is correct, not Axios
    })

    axios.interceptors.response.use((response: AxiosResponse<SharedType.BaseResponse>) => {
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

    axios.interceptors.request.use(async (axiosRequestConfig) => {
        // By default, serialize all requests to the format: { json, meta }
        const serializedReqObj = superjson.serialize(axiosRequestConfig.data)

        return { ...axiosRequestConfig, data: serializedReqObj }
    })

    return axios
}
