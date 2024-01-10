import { S3Client } from '@aws-sdk/client-s3'
import { S3Service } from '@maybe-finance/server/shared'
import env from '../../env'

// https://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/loading-node-credentials-environment.html
const s3Client = new S3Client({
    region: 'us-west-2',
})

const s3Service = new S3Service(s3Client, {
    public: env.NX_CDN_PUBLIC_BUCKET,
    private: env.NX_CDN_PRIVATE_BUCKET,
})

export default s3Service
