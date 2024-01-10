import type { AxiosInstance, AxiosRequestConfig } from 'axios'
import type {
    AddCustomerRequest,
    AddCustomerResponse,
    AuthenticationResponse,
    DeleteCustomerAccountsByInstitutionLoginRequest,
    DeleteCustomerAccountsByInstitutionLoginResponse,
    GenerateConnectUrlResponse,
    GenerateFixConnectUrlRequest,
    GenerateLiteConnectUrlRequest,
    GetAccountTransactionsRequest,
    GetAccountTransactionsResponse,
    GetCustomerAccountRequest,
    GetCustomerAccountResponse,
    GetCustomerAccountsRequest,
    GetCustomerAccountsResponse,
    GetInstitutionsRequest,
    GetInstitutionsResponse,
    LoadHistoricTransactionsRequest,
    RefreshCustomerAccountRequest,
    TxPushDisableRequest,
    TxPushSubscriptionRequest,
    TxPushSubscriptions,
} from './types'
import { DateTime } from 'luxon'
import axios from 'axios'

const is2xx = (status: number): boolean => status >= 200 && status < 300

/**
 * Basic typed mapping for Finicity API
 */
export class FinicityApi {
    private api: AxiosInstance | null = null
    private tokenTimestamp: DateTime | null = null

    constructor(
        private readonly appKey: string,
        private readonly partnerId: string,
        private readonly partnerSecret: string
    ) {}

    /**
     * Search for supported financial institutions
     *
     * https://api-reference.finicity.com/#/rest/api-endpoints/institutions/get-institutions
     */
    async getInstitutions(options: GetInstitutionsRequest): Promise<GetInstitutionsResponse> {
        return this.get<GetInstitutionsResponse>(`/institution/v2/institutions`, options)
    }

    /**
     * Enroll an active or testing customer
     *
     * https://api-reference.finicity.com/#/rest/api-endpoints/customer/add-customer
     */
    async addCustomer(options: AddCustomerRequest): Promise<AddCustomerResponse> {
        return this.post<AddCustomerResponse>(`/aggregation/v2/customers/active`, options)
    }

    /**
     * Enroll a testing customer
     *
     * https://api-reference.finicity.com/#/rest/api-endpoints/customer/add-testing-customer
     */
    async addTestingCustomer(options: AddCustomerRequest): Promise<AddCustomerResponse> {
        return this.post<AddCustomerResponse>(`/aggregation/v2/customers/testing`, options)
    }

    /**
     * Generate a Connect Lite URL
     *
     * https://api-reference.finicity.com/#/rest/api-endpoints/connect/generate-v2-lite-connect-url
     */
    async generateLiteConnectUrl(
        options: Omit<GenerateLiteConnectUrlRequest, 'partnerId'>
    ): Promise<GenerateConnectUrlResponse> {
        return this.post<{ link: string }>(`/connect/v2/generate/lite`, {
            partnerId: this.partnerId,
            ...options,
        })
    }

    /**
     * Generate a Fix Connect URL
     *
     * https://api-reference.finicity.com/#/rest/api-endpoints/connect/generate-v2-fix-connect-url
     */
    async generateFixConnectUrl(
        options: Omit<GenerateFixConnectUrlRequest, 'partnerId'>
    ): Promise<GenerateConnectUrlResponse> {
        return this.post<GenerateConnectUrlResponse>(`/connect/v2/generate/fix`, {
            partnerId: this.partnerId,
            ...options,
        })
    }

    /**
     * Get details for all accounts owned by a customer, optionally for a specific institution
     *
     * https://api-reference.finicity.com/#/rest/api-endpoints/accounts/get-customer-accounts
     */
    async getCustomerAccounts(
        options: GetCustomerAccountsRequest
    ): Promise<GetCustomerAccountsResponse> {
        const { customerId, ...rest } = options

        return this.get<GetCustomerAccountsResponse>(
            `/aggregation/v2/customers/${customerId}/accounts`,
            rest,
            {
                validateStatus: (status) => is2xx(status) && status !== 203,
            }
        )
    }

    /**
     * Get details for an account
     *
     * https://api-reference.finicity.com/#/rest/api-endpoints/accounts/get-customer-account
     */
    async getCustomerAccount(
        options: GetCustomerAccountRequest
    ): Promise<GetCustomerAccountResponse> {
        const { customerId, accountId, ...rest } = options

        return this.get<GetCustomerAccountResponse>(
            `/aggregation/v2/customers/${customerId}/accounts/${accountId}`,
            rest,
            {
                validateStatus: (status) => is2xx(status) && status !== 203,
            }
        )
    }

    /**
     * Refresh accounts
     *
     * https://api-reference.finicity.com/#/rest/api-endpoints/accounts/refresh-customer-accounts
     */
    async refreshCustomerAccounts({
        customerId,
    }: RefreshCustomerAccountRequest): Promise<GetCustomerAccountsResponse> {
        return this.post<GetCustomerAccountsResponse>(
            `/aggregation/v1/customers/${customerId}/accounts`,
            undefined,
            {
                timeout: 120_000,
                validateStatus: (status) => is2xx(status) && status !== 203,
            }
        )
    }

    async deleteCustomerAccountsByInstitutionLogin(
        options: DeleteCustomerAccountsByInstitutionLoginRequest
    ): Promise<DeleteCustomerAccountsByInstitutionLoginResponse> {
        const { customerId, institutionLoginId, ...rest } = options

        return this.delete<DeleteCustomerAccountsByInstitutionLoginResponse>(
            `/aggregation/v1/customers/${customerId}/institutionLogins/${institutionLoginId}`,
            rest
        )
    }

    /**
     * Get transactions for an account
     *
     * https://api-reference.finicity.com/#/rest/api-endpoints/transactions/get-customer-account-transactions
     */
    async getAccountTransactions(
        options: GetAccountTransactionsRequest
    ): Promise<GetAccountTransactionsResponse> {
        const { customerId, accountId, ...rest } = options

        return this.get<GetAccountTransactionsResponse>(
            `/aggregation/v4/customers/${customerId}/accounts/${accountId}/transactions`,
            rest,
            {
                validateStatus: (status) => is2xx(status) && status !== 203,
            }
        )
    }

    /**
     * Load historic transactions for an account
     *
     * https://api-reference.finicity.com/#/rest/api-endpoints/accounts/load-historic-transactions-for-customer-account
     */
    async loadHistoricTransactions({
        customerId,
        accountId,
    }: LoadHistoricTransactionsRequest): Promise<void> {
        await this.post(
            `/aggregation/v1/customers/${customerId}/accounts/${accountId}/transactions/historic`,
            {},
            {
                timeout: 180_000,
                validateStatus: (status) => is2xx(status) && status !== 203,
            } // 180 second timeout recommended by Finicity
        )
    }

    /**
     * Subscribe to TxPUSH notifications
     *
     * https://api-reference.finicity.com/#/rest/api-endpoints/txpush/subscribe-to-txpush-notifications
     */
    async subscribeTxPush({
        customerId,
        accountId,
        callbackUrl,
    }: TxPushSubscriptionRequest): Promise<TxPushSubscriptions> {
        return this.post(`/aggregation/v1/customers/${customerId}/accounts/${accountId}/txpush`, {
            callbackUrl,
        })
    }

    /**
     * Disable TxPUSH notifications
     *
     * https://api-reference.finicity.com/#/rest/api-endpoints/txpush/disable-txpush-notifications
     */
    async disableTxPush({ customerId, accountId }: TxPushDisableRequest): Promise<void> {
        await this.delete(`/aggregation/v1/customers/${customerId}/accounts/${accountId}/txpush`)
    }

    private async getApi(): Promise<AxiosInstance> {
        const tokenAge =
            this.tokenTimestamp && Math.abs(this.tokenTimestamp.diffNow('minutes').minutes)

        // Refresh token if over 90 minutes old (https://api-reference.finicity.com/#/rest/api-endpoints/authentication/partner-authentication)
        if (!this.api || !tokenAge || (tokenAge && tokenAge > 90)) {
            const token = (
                await axios.post<AuthenticationResponse>(
                    'https://api.finicity.com/aggregation/v2/partners/authentication',
                    {
                        partnerId: this.partnerId,
                        partnerSecret: this.partnerSecret,
                    },
                    {
                        headers: {
                            'Finicity-App-Key': this.appKey,
                            Accept: 'application/json',
                        },
                    }
                )
            ).data.token

            this.tokenTimestamp = DateTime.now()

            this.api = axios.create({
                baseURL: `https://api.finicity.com`,
                timeout: 30_000,
                headers: {
                    'Finicity-App-Token': token,
                    'Finicity-App-Key': this.appKey,
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
