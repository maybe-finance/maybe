/**
 * Custom storage engine for S3
 * @see https://github.com/expressjs/multer/blob/master/StorageEngine.md
 *
 * A simplified version of the `multer-s3` engine that properly supports
 * MD5 digests to satisfy S3 Object Lock PutObject requirements
 */

import type { StorageEngine } from 'multer'
import type { Logger } from 'winston'
import { v4 as uuid } from 'uuid'
import mime from 'mime-types'
import crypto from 'crypto'
import type { Request } from 'express'
import type { S3Service } from '@maybe-finance/server/shared'

type S3StorageOpts = {
    s3: S3Service
    getFilename?: (req: Request) => string
}

class S3Storage implements StorageEngine {
    constructor(private readonly opts: S3StorageOpts, private readonly logger: Logger) {
        if (!opts.s3) throw new Error('Must provide S3Client instance')
    }

    _handleFile(...params: Parameters<StorageEngine['_handleFile']>) {
        const [req, file, callback] = params

        const chunks: any[] = []

        file.stream.on('data', (chunk) => chunks.push(chunk))
        file.stream.on('end', () => {
            const Body = Buffer.concat(chunks)
            const md5Hash = crypto.createHash('md5').update(Body).digest('base64')

            const filename = this.opts.getFilename ? this.opts.getFilename(req) : null
            const Key = `${filename ?? uuid()}.${mime.extension(file.mimetype)}`

            this.logger.info(`Multer uploading file key=${Key} size=${Body.length}`)

            this.opts.s3
                .upload({
                    bucketKey: 'private',
                    Key,
                    Body,
                    ContentMD5: md5Hash,
                })
                .then(() => {
                    callback(null, {
                        size: Body.length,
                        path: Key,
                        mimetype: file.mimetype,
                    })
                })
        })
    }

    _removeFile(...params: Parameters<StorageEngine['_removeFile']>) {
        const [req, file, callback] = params

        this.logger.warn(`Multer removing file ${file.path}`)

        // Since object lock is turned on, this will create a new version, but never delete/overwrite
        this.opts.s3
            .delete({
                bucketKey: 'private',
                Key: file.path,
            })
            .then(() => callback(null))
            .catch((err) => callback(err))
    }
}

export default function (opts: S3StorageOpts, logger: Logger) {
    return new S3Storage(opts, logger) as StorageEngine
}
