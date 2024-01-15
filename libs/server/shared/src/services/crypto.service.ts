import crypto from 'crypto'

export interface ICryptoService {
    encrypt(plainText: string): string
    decrypt(encrypted: string): string
}

export class CryptoService implements ICryptoService {
    private key: Buffer
    private ivLength = 16 // Initialization vector length. For AES, this is always 16

    constructor(private readonly secret: string) {
        // Ensure the key length is suitable for AES-256
        this.key = crypto.createHash('sha256').update(String(this.secret)).digest()
    }

    encrypt(plainText: string) {
        const iv = crypto.randomBytes(this.ivLength)
        const cipher = crypto.createCipheriv('aes-256-cbc', this.key, iv)
        let encrypted = cipher.update(plainText, 'utf8', 'hex')
        encrypted += cipher.final('hex')

        // Include the IV at the start of the encrypted result
        return iv.toString('hex') + ':' + encrypted
    }

    decrypt(encrypted: string) {
        const textParts = encrypted.split(':')
        const iv = Buffer.from(textParts.shift()!, 'hex')
        const encryptedText = textParts.join(':')
        const decipher = crypto.createDecipheriv('aes-256-cbc', this.key, iv)
        let decrypted = decipher.update(encryptedText, 'hex', 'utf8')
        decrypted += decipher.final('utf8')

        return decrypted
    }
}
