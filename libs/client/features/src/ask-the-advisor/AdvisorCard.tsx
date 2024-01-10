import type { SharedType } from '@maybe-finance/shared'
import { Badge } from '@maybe-finance/design-system'
import classNames from 'classnames'
import upperFirst from 'lodash/upperFirst'
import { RiUserSearchLine } from 'react-icons/ri'

export type AdvisorCardProps = {
    advisor: SharedType.AdvisorProfile
    status: 'online' | 'offline'
    mode?: 'default' | 'wide' | 'wide-standalone'
}

export function AdvisorCard({ mode = 'default', ...props }: AdvisorCardProps) {
    return mode === 'default' ? (
        <AdvisorCardDesktop {...props} mode={mode} />
    ) : (
        <AdvisorCardWide {...props} mode={mode} />
    )
}

export function NoAdvisorCardDesktop({
    mode = 'default',
}: {
    mode?: 'default' | 'wide-standalone'
}) {
    return (
        <div
            className={classNames(
                'rounded-lg bg-gray-800 p-6 space-y-4 text-center',
                mode === 'default' ? 'w-[303px]' : 'w-full'
            )}
        >
            <p className="text-gray-100 text-sm whitespace-nowrap">Assigned advisor</p>
            <div className="bg-gray-700 h-12 w-12 flex items-center justify-center rounded-full mx-auto">
                <RiUserSearchLine size={20} className="text-gray-50" />
            </div>
            <p className="text-gray-25 text-base">
                Currently finding you an advisor who can best answer your question...
            </p>

            {/* TODO - add this when we enable email support  */}
            {/* <div className="flex items-center gap-2 text-gray-50 text-base whitespace-nowrap">
            <RiMailUnreadLine size={16} className="shrink-0" />
            We&lsquo;ll email you once we find a match
        </div> */}
        </div>
    )
}

function AdvisorCardDesktop({ status, advisor }: AdvisorCardProps) {
    return (
        <div className="flex flex-col items-center bg-gray-800 p-6 text-center rounded-lg text-base text-gray-50 space-y-3 w-[300px]">
            <p className="text-gray-100">Assigned advisor</p>

            <div className="relative h-20 w-20">
                <div
                    className={classNames(
                        'absolute bottom-0 right-3 w-4 h-4 rounded-full border-2 border-gray-700',
                        status === 'online' ? 'bg-teal' : 'bg-yellow'
                    )}
                ></div>
                <img alt={`${advisor.fullName}-advisor-avatar`} src={advisor.avatarSrc} />
            </div>

            <p className="text-white">{advisor.fullName}</p>
            <p className="max-w-[200px]">{advisor.title}</p>
        </div>
    )
}

function AdvisorCardWide({ status, advisor, mode }: AdvisorCardProps) {
    return (
        <div
            className={classNames(
                'p-3 rounded-lg text-base text-gray-50 space-y-3',
                mode === 'wide-standalone' ? 'bg-gray-800' : 'bg-gray-700'
            )}
        >
            <p className="text-gray-100 text-sm">Assigned advisor</p>

            <div className="flex gap-2">
                <div className="relative h-12 w-12">
                    <img alt={`${advisor.fullName}-advisor-avatar`} src={advisor.avatarSrc} />
                </div>

                <div className="">
                    <div className="flex items-center gap-2 text-white">
                        {advisor.fullName}
                        <Badge
                            size="sm"
                            className="inline-flex items-center gap-1 h-5"
                            variant={status === 'online' ? 'teal' : 'warn'}
                        >
                            <div
                                className={classNames(
                                    'w-1.5 h-1.5 rounded-full',
                                    status === 'online' ? 'bg-teal' : 'bg-yellow'
                                )}
                            ></div>{' '}
                            {upperFirst(status)}
                        </Badge>
                    </div>
                    <p>{advisor.title}</p>
                </div>
            </div>
        </div>
    )
}
