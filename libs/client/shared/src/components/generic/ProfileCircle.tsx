import classNames from 'classnames'
import { useUserApi } from '../../api'

const getProfileInitials = (nameString: string): string => {
    const parts = nameString.split(' ')
    if (parts.length === 1) {
        return parts[0].charAt(0)
    }

    return parts[0].charAt(0) + parts[1].charAt(0)
}

export type ProfileCircleProps = {
    interactive?: boolean
    className?: string
}

export function ProfileCircle({ interactive = true, className }: ProfileCircleProps) {
    const { useProfile } = useUserApi()
    const profile = useProfile()

    const firstName = profile.data?.firstName
    const lastName = profile.data?.lastName
    const name = !firstName ? lastName : !lastName ? firstName : `${firstName} ${lastName}`

    return (
        <div
            className={classNames(
                'flex items-center justify-center w-12 h-12 text-base font-semibold rounded-full text-cyan bg-cyan bg-opacity-10',
                interactive && 'hover:bg-opacity-20 cursor-pointer',
                className
            )}
        >
            {getProfileInitials(name ?? 'M')}
        </div>
    )
}
