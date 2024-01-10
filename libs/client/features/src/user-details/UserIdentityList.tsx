import type { SharedType } from '@maybe-finance/shared'
import { ConfirmDialog, useModalManager, useUserApi } from '@maybe-finance/client/shared'
import { useState } from 'react'
import { UserIdentityCard } from './UserIdentityCard'

export function UserIdentityList({ profile }: { profile: SharedType.Auth0Profile }) {
    const { useUnlinkAccount } = useUserApi()
    const { dispatch } = useModalManager()
    const [isConfirm, setIsConfirm] = useState(false)
    const [unlinkProps, setUnlinkProps] = useState<SharedType.UnlinkAccount | undefined>(undefined)
    const unlinkAccountQuery = useUnlinkAccount()
    const { primaryIdentity, secondaryIdentities, suggestedIdentities, email } = profile

    return (
        <>
            <div className="mt-4 text-base">
                <p className="text-gray-50 mb-2">Identities</p>
                <div className="space-y-2">
                    {/* The user's primary account identity */}
                    <UserIdentityCard
                        key="primary"
                        identity={{
                            variant: 'primary',
                            provider: primaryIdentity.provider,
                            email: email!,
                            isLinked: secondaryIdentities.length > 0,
                        }}
                    />

                    {/* Any identities the user has already linked */}
                    {secondaryIdentities.map((si) => (
                        <UserIdentityCard
                            key={si.user_id}
                            identity={{
                                variant: 'linked',
                                provider: si.provider,
                                email: si.profileData?.email ?? email!,
                                auth0Id: si.user_id,
                            }}
                            onUnlink={(data) => {
                                setUnlinkProps(data)
                                setIsConfirm(true)
                            }}
                        />
                    ))}

                    {/* Accounts that can be linked */}
                    {suggestedIdentities.map((si) => (
                        <UserIdentityCard
                            key={si.user_id}
                            identity={{
                                variant: 'unlinked',
                                provider: si.provider,
                                email,
                            }}
                            onLink={() =>
                                dispatch({
                                    type: 'open',
                                    key: 'linkAuth0Accounts',
                                    props: { secondaryProvider: si.provider },
                                })
                            }
                        />
                    ))}

                    {/* If the primary is an email/password account and has no linked or suggested identities,
                        we can suggest they link an Apple account */}
                    {!primaryIdentity.isSocial &&
                        !secondaryIdentities.length &&
                        !suggestedIdentities.length && (
                            <UserIdentityCard
                                key="apple-auto-suggested"
                                identity={{
                                    variant: 'unlinked',
                                    provider: 'apple',
                                }}
                                onLink={() =>
                                    dispatch({
                                        type: 'open',
                                        key: 'linkAuth0Accounts',
                                        props: { secondaryProvider: 'apple' },
                                    })
                                }
                            />
                        )}
                </div>
            </div>
            <ConfirmDialog
                isOpen={isConfirm}
                onCancel={() => setIsConfirm(false)}
                onConfirm={async () => {
                    setIsConfirm(false)
                    await unlinkAccountQuery.mutateAsync(unlinkProps!)
                }}
                title="Unlink account?"
            >
                <div className="mt-4 text-base text-gray-50 space-y-2">
                    <p>
                        Unlinking this account will remove the connection permanently.{' '}
                        <span className="text-white">No data will be lost.</span>
                    </p>
                    <p>
                        After unlinking, each login will become a{' '}
                        <span className="text-white">separate</span> Maybe account.
                    </p>
                </div>
            </ConfirmDialog>
        </>
    )
}
