import type { SharedType } from '@maybe-finance/shared'
import type { AxiosInstance } from 'axios'
import axios from 'axios'
import env from '../../env'

class ConvertKitApi {
    private axios: AxiosInstance

    constructor(private readonly apiSecret: string) {
        this.axios = axios.create({
            baseURL: 'https://api.convertkit.com/v3',
        })
    }

    async getSubscription(subscriberId: number | null) {
        // Until we have the id stored in DB, assume no subscription
        if (!subscriberId) {
            return {
                isSubscribed: false,
            }
        }

        const res = await this.axios.get<{ subscriber: SharedType.ConvertKitSubscriber }>(
            `/subscribers/${subscriberId}`,
            {
                params: {
                    api_secret: this.apiSecret,
                },
            }
        )

        return {
            isSubscribed: res.data ? res.data.subscriber.state === 'active' : false,
            subscriber: res.data.subscriber,
        }
    }

    async subscribe(email: string) {
        const res = await this.axios.post<{ subscription: SharedType.ConvertKitSubscription }>(
            '/forms/2279973/subscribe', // The main mailing list ID
            {
                api_secret: this.apiSecret,
                email,
            }
        )

        return res.data
    }

    async unsubscribe(email: string) {
        const res = await this.axios.put<{ subscriber: SharedType.ConvertKitSubscriber }>(
            '/unsubscribe',
            {
                api_secret: this.apiSecret,
                email,
            }
        )

        return res.data
    }
}

// Prevent multiple instances of S3 client
const convertKit = new ConvertKitApi(env.NX_CONVERTKIT_SECRET)

export default convertKit
