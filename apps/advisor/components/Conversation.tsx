import { Attachment, RelativeTime, RichText } from '@maybe-finance/client/shared'
import type { RouterOutput } from '../lib/trpc'

type Props = {
    me: RouterOutput['users']['me']
    conversation: RouterOutput['advisor']['conversations']['get']
}

export default function Conversation({ me, conversation }: Props) {
    return (
        <ul role="list">
            {conversation.messages.map((message, idx) => {
                const isMe = message.userId === me.id
                const advisor = message.user?.advisor

                return (
                    <li key={message.id} className="relative pb-6">
                        {/* border */}
                        {idx !== conversation.messages.length - 1 && (
                            <span
                                className="absolute top-14 bottom-4 left-4 ml-px w-0.5 bg-gray-600"
                                aria-hidden="true"
                            />
                        )}

                        <div className="flex items-start space-x-4">
                            {/* avatar */}
                            <div>
                                <img
                                    className="h-9 w-9 rounded-full bg-gray-400"
                                    src={
                                        advisor
                                            ? advisor.avatarSrc
                                            : message.userId === conversation.userId
                                            ? conversation.user.picture ?? undefined
                                            : undefined
                                    }
                                    alt=""
                                />
                            </div>

                            <div className="mt-1 min-w-0 flex-1 space-y-2">
                                {/* header */}
                                <div className="text-base space-x-1.5">
                                    <span className="text-gray-25">
                                        {isMe
                                            ? 'You'
                                            : advisor
                                            ? advisor.fullName
                                            : message.userId === conversation.userId
                                            ? conversation.user.name
                                            : ''}
                                    </span>
                                    <span className="text-gray-100">·</span>
                                    <span className="text-gray-100">
                                        <RelativeTime time={message.createdAt} />
                                    </span>
                                </div>

                                {/* text */}
                                <div className="px-4 py-3 bg-gray-800 rounded-md">
                                    <RichText text={message.body} />
                                </div>

                                {/* media */}
                                {message.mediaSrc &&
                                    (message.type === 'video' ? (
                                        <video controls src={message.mediaSrc} />
                                    ) : message.type === 'audio' ? (
                                        <audio controls src={message.mediaSrc} />
                                    ) : (
                                        <Attachment href={message.mediaSrc} />
                                    ))}
                            </div>
                        </div>
                    </li>
                )
            })}
        </ul>
    )
}
