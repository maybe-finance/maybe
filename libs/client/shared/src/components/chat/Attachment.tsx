import classNames from 'classnames'
import { RiDownloadLine } from 'react-icons/ri'

type Props = {
    href: string
}

// Displays a generic file
export function Attachment({ href }: Props) {
    const url = new URL(href)
    const name = url.pathname.split('/').at(-1)
    const ext = name?.split('.').at(-1)

    // In general, don't do any special UI for generic attachments, but for images, try to render with img element
    const imageExtensions = ['png', 'jpeg', 'jpg', 'webp', 'gif']

    return (
        <div className="flex flex-col justify-end gap-2">
            {imageExtensions.includes(ext ?? '') && <img src={href} alt={name} />}

            <div>
                <span className="text-sm text-gray-50 inline-block mb-1">Message attachment</span>
                <a
                    href={href}
                    className={classNames(
                        'flex items-center gap-3 text-base w-fit bg-gray-600 px-2 py-1 rounded hover:bg-gray-500'
                    )}
                    download
                >
                    <span className="truncate max-w-[250px]">{name}</span>
                    <RiDownloadLine size={18} />
                </a>
            </div>
        </div>
    )
}
