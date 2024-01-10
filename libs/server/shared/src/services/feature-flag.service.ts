import type { LDClient, LDUser } from 'launchdarkly-node-server-sdk'

export interface IFeatureFlagService {
    getFlag<TValue = any>(flagKey: string, defaultValue: TValue, user?: LDUser): Promise<TValue>
}

export class LaunchDarklyFeatureFlagService implements IFeatureFlagService {
    constructor(private readonly ldClient: LDClient) {}

    async getFlag<TValue = any>(
        flagKey: string,
        defaultValue: TValue,
        user?: LDUser
    ): Promise<TValue> {
        if (!this.ldClient) return defaultValue

        await this.ldClient.waitForInitialization()

        return await this.ldClient.variation(
            flagKey,
            user ?? { key: 'anonymous-server', anonymous: true },
            defaultValue
        )
    }
}
