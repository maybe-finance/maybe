import type { AxiosInstance, AxiosRequestConfig } from 'axios'
import type {
    Account,
    AccountBalance,
    AccountDetails,
    Identity,
    Transaction,
    GetAccountResponse,
    GetAccountsResponse,
    GetAccountBalancesResponse,
    GetIdentityResponse,
    GetTransactionResponse,
    GetTransactionsResponse,
    DeleteAccountResponse,
    GetAccountDetailsResponse,
    WebhookData,
} from './types'
import { DateTime } from 'luxon'
import axios from 'axios'
import * as fs from 'fs'
import * as https from 'https'

const is2xx = (status: number): boolean => status >= 200 && status < 300

/**
 * Basic typed mapping for Teller API
 */
export class TellerApi {
    private api: AxiosInstance | null = null

    private async getApi(): Promise<AxiosInstance> {
        const cert = fs.readFileSync('../../../certs/teller-certificate.pem', 'utf8')
        const key = fs.readFileSync('../../../certs/teller-private-key.pem', 'utf8')

        const agent = new https.Agent({
            cert,
            key,
        })

        if (!this.api) {
            this.api = axios.create({
                httpsAgent: agent,
                baseURL: `https://api.teller.io`,
                timeout: 30_000,
                headers: {
                    Accept: 'application/json',
                },
            })
        }

        return this.api
    }

    /** Generic API GET request method */
    private async get<TResponse>(
        path: string,
        params?: any,
        config?: AxiosRequestConfig
    ): Promise<TResponse> {
        const api = await this.getApi()
        return api.get<TResponse>(path, { params, ...config }).then(({ data }) => data)
    }

    /** Generic API POST request method */
    private async post<TResponse>(
        path: string,
        body?: any,
        config?: AxiosRequestConfig
    ): Promise<TResponse> {
        const api = await this.getApi()
        return api.post<TResponse>(path, body, config).then(({ data }) => data)
    }

    /** Generic API DELETE request method */
    private async delete<TResponse>(
        path: string,
        params?: any,
        config?: AxiosRequestConfig
    ): Promise<TResponse> {
        const api = await this.getApi()
        return api.delete<TResponse>(path, { params, ...config }).then(({ data }) => data)
    }
}
