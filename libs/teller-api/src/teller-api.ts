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
    GetInstitutionsResponse,
    AuthenticatedRequest,
    GetAccountRequest,
    DeleteAccountRequest,
    GetAccountDetailsRequest,
    GetAccountBalancesRequest,
    GetTransactionsRequest,
    GetTransactionRequest,
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

    async getAccounts({ accessToken }: AuthenticatedRequest): Promise<GetAccountsResponse> {
        return this.get<GetAccountsResponse>(`/accounts`, accessToken)
    }

    /**
     * Get a single account by id
     *
     * https://teller.io/docs/api/accounts
     */

    async getAccount({ accountId, accessToken }: GetAccountRequest): Promise<GetAccountResponse> {
        return this.get<GetAccountResponse>(`/accounts/${accountId}`, accessToken)
    }

    /**
     * Delete the application's access to an account. Does not delete the account itself.
     *
     * https://teller.io/docs/api/accounts
     */

    async deleteAccount({
        accountId,
        accessToken,
    }: DeleteAccountRequest): Promise<DeleteAccountResponse> {
        return this.delete<DeleteAccountResponse>(`/accounts/${accountId}`, accessToken)
    }

    /**
     * Get account details for a single account
     *
     * https://teller.io/docs/api/account/details
     */

    async getAccountDetails({
        accountId,
        accessToken,
    }: GetAccountDetailsRequest): Promise<GetAccountDetailsResponse> {
        return this.get<GetAccountDetailsResponse>(`/accounts/${accountId}/details`, accessToken)
    }

    /**
     * Get account balances for a single account
     *
     * https://teller.io/docs/api/account/balances
     */

    async getAccountBalances({
        accountId,
        accessToken,
    }: GetAccountBalancesRequest): Promise<GetAccountBalancesResponse> {
        return this.get<GetAccountBalancesResponse>(`/accounts/${accountId}/balances`, accessToken)
    }

    /**
     * Get transactions for a single account
     *
     * https://teller.io/docs/api/transactions
     */

    async getTransactions({
        accountId,
        accessToken,
    }: GetTransactionsRequest): Promise<GetTransactionsResponse> {
        return this.get<GetTransactionsResponse>(`/accounts/${accountId}/transactions`, accessToken)
    }

    /**
     * Get a single transaction by id
     *
     * https://teller.io/docs/api/transactions
     */

    async getTransaction({
        accountId,
        transactionId,
        accessToken,
    }: GetTransactionRequest): Promise<GetTransactionResponse> {
        return this.get<GetTransactionResponse>(
            `/accounts/${accountId}/transactions/${transactionId}`,
            accessToken
        )
    }

    /**
     * Get identity for a single account
     *
     * https://teller.io/docs/api/identity
     */

    async getIdentity({ accessToken }: AuthenticatedRequest): Promise<GetIdentityResponse> {
        return this.get<GetIdentityResponse>(`/identity`, accessToken)
    }

    /**
     * Get list of supported institutions, access token not needed
     *
     * https://teller.io/docs/api/identity
     */

    async getInstitutions(): Promise<GetInstitutionsResponse> {
        return this.get<GetInstitutionsResponse>(`/institutions`, '')
    }

    private async getApi(accessToken: string): Promise<AxiosInstance> {
        const cert = fs.readFileSync('./certs/certificate.pem')
        const key = fs.readFileSync('./certs/private_key.pem')

        const agent = new https.Agent({
            cert: cert,
            key: key,
        })

        if (!this.api) {
            this.api = axios.create({
                httpsAgent: agent,
                baseURL: `https://api.teller.io`,
                timeout: 30_000,
                headers: {
                    Accept: 'application/json',
                },
                auth: {
                    username: accessToken,
                    password: '',
                },
            })
        }

        return this.api
    }

    /** Generic API GET request method */
    private async get<TResponse>(
        path: string,
        accessToken: string,
        params?: any,
        config?: AxiosRequestConfig
    ): Promise<TResponse> {
        const api = await this.getApi(accessToken)
        return api.get<TResponse>(path, { params, ...config }).then(({ data }) => data)
    }

    /** Generic API POST request method */
    private async post<TResponse>(
        path: string,
        accessToken: string,
        body?: any,
        config?: AxiosRequestConfig
    ): Promise<TResponse> {
        const api = await this.getApi(accessToken)
        return api.post<TResponse>(path, body, config).then(({ data }) => data)
    }

    /** Generic API DELETE request method */
    private async delete<TResponse>(
        path: string,
        accessToken: string,
        params?: any,
        config?: AxiosRequestConfig
    ): Promise<TResponse> {
        const api = await this.getApi(accessToken)
        return api.delete<TResponse>(path, { params, ...config }).then(({ data }) => data)
    }
}
