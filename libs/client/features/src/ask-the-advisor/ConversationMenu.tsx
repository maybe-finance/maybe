import type { Conversation } from '@prisma/client'
import { useConversationApi } from '@maybe-finance/client/shared'
import { Menu } from '@maybe-finance/design-system'
import { RiCheckDoubleLine } from 'react-icons/ri'

type Props = {
    conversationId: Conversation['id']
}

export function ConversationMenu({ conversationId }: Props) {
    const { useUpdateConversation, useSandbox } = useConversationApi()
    const sandbox = useSandbox()
    const update = useUpdateConversation()

    return (
        <Menu>
            <Menu.Button variant="icon">
                <i className="ri-more-2-fill text-white" />
            </Menu.Button>
            <Menu.Items placement="bottom-end">
                <Menu.Item
                    icon={<RiCheckDoubleLine />}
                    onClick={() => {
                        update.mutate({ id: conversationId, data: { status: 'closed' } })
                    }}
                >
                    Mark as complete
                </Menu.Item>

                {/* Dev only utils */}
                {process.env.NODE_ENV === 'development' && (
                    <Menu.Item
                        destructive
                        onClick={() => sandbox.mutate({ action: 'assign-advisor', conversationId })}
                    >
                        DEV ONLY: Assign advisor
                    </Menu.Item>
                )}
            </Menu.Items>
        </Menu>
    )
}
