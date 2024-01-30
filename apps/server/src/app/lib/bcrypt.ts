import { genSaltSync, hashSync } from 'bcrypt'

export const encodePassword = (rawPassword: string) => {
    const SALT = genSaltSync()
    return hashSync(rawPassword, SALT)
}
