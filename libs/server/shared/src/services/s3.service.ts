import {
    type S3Client,
    type PutObjectCommandOutput,
    type PutObjectCommandInput,
    type DeleteObjectCommandInput,
    type DeleteObjectCommandOutput,
    PutObjectCommand,
    DeleteObjectCommand,
} from '@aws-sdk/client-s3'

import { v4 as uuid } from 'uuid'

type UploadOptions = {
    bucketKey: BucketKey
    Key?: string
} & Omit<PutObjectCommandInput, 'Bucket' | 'Key'>

type DeleteOptions = {
    bucketKey: BucketKey
    Key: string
} & Omit<DeleteObjectCommandInput, 'Bucket' | 'Key'>

export interface IS3Service {
    upload(opts?: UploadOptions): Promise<PutObjectCommandOutput & { Key: string }>
    delete(opts: DeleteOptions): Promise<DeleteObjectCommandOutput & { Key: string }>
}

export type BucketKey = 'public' | 'private'

export class S3Service implements IS3Service {
    constructor(readonly cli: S3Client, readonly buckets: Record<BucketKey, string>) {}

    async upload({ bucketKey, Key = uuid(), ...rest }: UploadOptions) {
        const uploadRes = await this.cli.send(
            new PutObjectCommand({
                Bucket: this.buckets[bucketKey],
                Key,
                ...rest,
            })
        )

        return {
            ...uploadRes,
            Key,
        }
    }

    async delete({ bucketKey, Key, ...rest }: DeleteOptions) {
        const deleteRes = await this.cli.send(
            new DeleteObjectCommand({
                Bucket: this.buckets[bucketKey],
                Key,
                ...rest,
            })
        )

        return {
            ...deleteRes,
            Key,
        }
    }
}
