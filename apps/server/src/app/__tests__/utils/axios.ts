import type { AxiosResponse } from 'axios'
import type { SharedType } from '@maybe-finance/shared'
import { superjson } from '@maybe-finance/shared'
import env from '../../../env'
import isCI from 'is-ci'
import Axios from 'axios'

// Fetches Auth0 access token (JWT) and prepares Axios client to use it on each request
export async function getAxiosClient() {
    const tenantUrl = isCI
        ? 'REPLACE_THIS-staging.us.auth0.com'
        : 'REPLACE_THIS-development.us.auth0.com'

    const {
        data: { access_token: token },
    } = await Axios.request({
        method: 'POST',
        url: `https://${tenantUrl}/oauth/token`,
        headers: { 'content-type': 'application/json' },
        data: {
            grant_type: 'password',
            username: 'REPLACE_THIS',
            password: 'REPLACE_THIS',
            audience: 'https://maybe-finance-api/v1',
            scope: '',
            client_id: isCI
                ? 'REPLACE_THIS'
                : 'REPLACE_THIS',
            client_secret: env.NX_AUTH0_CLIENT_SECRET,
        },
    })

    const axios = Axios.create({
        baseURL: 'http://127.0.0.1:53333/v1',
        validateStatus: () => true, // Tests should determine whether status is correct, not Axios
        headers: {
            Authorization: `Bearer ${token}`,
        },
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
