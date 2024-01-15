import type { AxiosInstance, AxiosRequestConfig } from 'axios'
import type {
    GetAccountResponse,
    GetAccountsResponse,
    GetAccountBalancesResponse,
    GetIdentityResponse,
    GetTransactionResponse,
    GetTransactionsResponse,
    DeleteAccountResponse,
    GetAccountDetailsResponse,
} from './types'
import axios from 'axios'
import * as fs from 'fs'
import * as https from 'https'

/**
 * Basic typed mapping for Teller API
 */
export class TellerApi {
    private api: AxiosInstance | null = null

    /**
     * List accounts a user granted access to in Teller Connect
     *
     * https://teller.io/docs/api/accounts
     */

    async getAccounts(): Promise<GetAccountsResponse> {
        return this.get<GetAccountsResponse>(`/accounts`)
    }

    /**
     * Get a single account by id
     *
     * https://teller.io/docs/api/accounts
     */

    async getAccount(accountId: string): Promise<GetAccountResponse> {
        return this.get<GetAccountResponse>(`/accounts/${accountId}`)
    }

    /**
     * Delete the application's access to an account. Does not delete the account itself.
     *
     * https://teller.io/docs/api/accounts
     */

    async deleteAccount(accountId: string): Promise<DeleteAccountResponse> {
        return this.delete<DeleteAccountResponse>(`/accounts/${accountId}`)
    }

    /**
     * Get account details for a single account
     *
     * https://teller.io/docs/api/account/details
     */

    async getAccountDetails(accountId: string): Promise<GetAccountDetailsResponse> {
        return this.get<GetAccountDetailsResponse>(`/accounts/${accountId}/details`)
    }

    /**
     * Get account balances for a single account
     *
     * https://teller.io/docs/api/account/balances
     */

    async getAccountBalances(accountId: string): Promise<GetAccountBalancesResponse> {
        return this.get<GetAccountBalancesResponse>(`/accounts/${accountId}/balances`)
    }

    /**
     * Get transactions for a single account
     *
     * https://teller.io/docs/api/transactions
     */

    async getTransactions(accountId: string): Promise<GetTransactionsResponse> {
        return this.get<GetTransactionsResponse>(`/accounts/${accountId}/transactions`)
    }

    /**
     * Get a single transaction by id
     *
     * https://teller.io/docs/api/transactions
     */

    async getTransaction(
        accountId: string,
        transactionId: string
    ): Promise<GetTransactionResponse> {
        return this.get<GetTransactionResponse>(
            `/accounts/${accountId}/transactions/${transactionId}`
        )
    }

    /**
     * Get identity for a single account
     *
     * https://teller.io/docs/api/identity
     */

    async getIdentity(): Promise<GetIdentityResponse> {
        return this.get<GetIdentityResponse>(`/identity`)
    }

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
