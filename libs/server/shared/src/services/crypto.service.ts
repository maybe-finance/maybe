import CryptoJS from 'crypto-js'

export interface ICryptoService {
    encrypt(plainText: string): string
    decrypt(encrypted: string): string
}

export class CryptoService implements ICryptoService {
    constructor(private readonly secret: string) {}

    encrypt(plainText: string) {
        return CryptoJS.AES.encrypt(plainText, this.secret).toString()
    }

    decrypt(encrypted: string) {
        return CryptoJS.AES.decrypt(encrypted, this.secret).toString(CryptoJS.enc.Utf8)
    }
}
