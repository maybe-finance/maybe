import type { SharedType } from '@maybe-finance/shared'
import { Button } from '@maybe-finance/design-system'
import { RiAppleFill, RiMailLine, RiCheckboxCircleFill } from 'react-icons/ri'

export type UserIdentity =
    | {
          variant: 'primary'
          provider: string
          email: string
          auth0Id?: string
          isLinked?: boolean
      }
    | {
          variant: 'linked'
          provider: string
          email: string
          auth0Id: string
          isLinked?: never
      }
    | {
          variant: 'unlinked'
          provider: string
          email?: string // We might have an email here if we've detected a duplicate account
          auth0Id?: never
          isLinked?: never
      }

export function UserIdentityCard({
    identity,
    onUnlink,
    onLink,
}: {
    identity: UserIdentity
    onUnlink?(data: SharedType.UnlinkAccount): void
    onLink?(): void
}) {
    return (
        <div className="flex items-center bg-gray-800 rounded-lg p-4">
            <div className="flex items-center justify-center w-12">
                {identity.provider === 'apple' ? (
                    <RiAppleFill className="w-8 h-8" />
                ) : (
                    <RiMailLine className="w-8 h-8" />
                )}
            </div>

            <div className="ml-4 flex flex-col justify-around text-white">
                <span>{identity.email ?? ''}</span>
                <div className="flex items-center">
                    {!identity.email && (
                        <span className="text-gray-100">
                            {identity.provider === 'apple' ? 'Apple account' : 'Email account'}
                        </span>
                    )}
                    {identity.variant === 'primary' && (
                        <span className="inline-flex items-center text-sm text-cyan-400">
                            <RiCheckboxCircleFill className="w-4 h-4 mr-1" />
                            Main
                        </span>
                    )}
                </div>
            </div>

            {identity.isLinked && (
                <span className="ml-auto inline-flex items-center text-base font-medium text-teal">
                    <RiCheckboxCircleFill className="w-5 h-5 mr-2" />
                    Linked
                </span>
            )}

            {identity.variant === 'linked' && (
                <Button
                    variant="secondary"
                    className="ml-auto"
                    onClick={() =>
                        onUnlink?.({
                            secondaryAuth0Id: identity.auth0Id,
                            secondaryProvider: identity.provider,
                        })
                    }
                >
                    Unlink
                </Button>
            )}

            {identity.variant === 'unlinked' && (
                <Button variant="secondary" className="ml-auto" onClick={onLink}>
                    Link
                </Button>
            )}
        </div>
    )
}
