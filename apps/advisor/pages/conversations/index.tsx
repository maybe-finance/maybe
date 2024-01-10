import { withPageAuthRequired } from '@auth0/nextjs-auth0'
import { RiInboxLine } from 'react-icons/ri'
import Conversations from '../../components/Conversations'
import Layout from '../../components/Layout'

export const getServerSideProps = withPageAuthRequired()

export default function ConversationsPage() {
    return (
        <div className="h-full flex flex-col items-center justify-center">
            <RiInboxLine className="h-10 w-10 text-gray-100" />
            <h3 className="mt-2 text-base font-medium text-white">Inbox</h3>
            <p className="mt-1 text-sm text-gray-100">Select a conversation to get started!</p>
        </div>
    )
}

ConversationsPage.getLayout = (page) => (
    <Layout>
        <Conversations>{page}</Conversations>
    </Layout>
)
