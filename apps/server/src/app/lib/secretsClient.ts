import { SecretsManagerClient } from '@aws-sdk/client-secrets-manager'

const secretsClient = new SecretsManagerClient({
    region: 'us-west-2',
})

export default secretsClient
