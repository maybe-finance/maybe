import type { User } from '@auth0/auth0-react'

export function hasRole(user: User | null | undefined, role: 'Admin' | 'Advisor'): boolean {
    if (!user) return false
    const roles = user['https://maybe.co/roles']
    return roles && Array.isArray(roles) && roles.includes(role)
}
