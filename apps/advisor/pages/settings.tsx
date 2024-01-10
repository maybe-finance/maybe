import { withPageAuthRequired } from '@auth0/nextjs-auth0'
import Layout from '../components/Layout'

export const getServerSideProps = withPageAuthRequired()

export default function SettingsPage() {
    return <div>ToDo</div>
}

SettingsPage.getLayout = (page) => <Layout>{page}</Layout>
