import Link from 'next/link'
import { useState } from 'react'
import {
    useAccountConnectionApi,
    useInstitutionApi,
    useSecurityApi,
    useUserApi,
} from '@maybe-finance/client/shared'
import { Button, Input, Dialog } from '@maybe-finance/design-system'
import { type SubmitHandler, useForm } from 'react-hook-form'
import { toast } from 'react-hot-toast'

export function AccountDevTools() {
    const [open, setOpen] = useState(false)

    const { useDeleteAllConnections } = useAccountConnectionApi()
    const { useSyncInstitutions, useDeduplicateInstitutions } = useInstitutionApi()
    const { useSyncUSStockTickers, useSyncSecurityPricing } = useSecurityApi()

    const deleteAllConnections = useDeleteAllConnections()
    const syncInstitutions = useSyncInstitutions()
    const deduplicateInstitutions = useDeduplicateInstitutions()
    const syncUSStockTickers = useSyncUSStockTickers()
    const syncSecurityPricing = useSyncSecurityPricing()

    return process.env.NODE_ENV === 'development' ? (
        <div className="relative mb-12 mx-2 sm:mx-0 p-4 bg-gray-700 rounded-md z-10">
            <h6 className="flex text-red">
                Dev Tools <i className="ri-tools-fill ml-1.5" />
            </h6>
            <p className="text-sm my-2">
                This section along with anything in <span className="text-red">red text</span> will
                NOT show in production and are solely for making testing easier.
            </p>
            <div className="flex items-center text-sm mt-4">
                <p className="font-bold">Actions:</p>
                <button
                    className="underline text-red ml-4"
                    onClick={() => deleteAllConnections.mutate()}
                >
                    Delete all connections
                </button>
                <Link href="http://localhost:3333/admin/bullmq" className="underline text-red ml-4">
                    BullMQ Dashboard
                </Link>
                <button
                    className="underline text-red ml-4"
                    onClick={() => syncInstitutions.mutate()}
                >
                    Sync institutions
                </button>
                <button
                    className="underline text-red ml-4"
                    onClick={() => deduplicateInstitutions.mutate()}
                >
                    Deduplicate institutions
                </button>
                <button
                    className="underline text-red ml-4"
                    onClick={() => syncUSStockTickers.mutate()}
                >
                    Sync stock tickers
                </button>
                <button
                    className="underline text-red ml-4"
                    onClick={() => syncSecurityPricing.mutate()}
                >
                    Sync stock pricing
                </button>
                <button className="underline text-red ml-4" onClick={() => setOpen(true)}>
                    Test email
                </button>
            </div>
            <Dialog isOpen={open} onClose={() => setOpen(false)}>
                <Dialog.Title>Send test email</Dialog.Title>
                <Dialog.Content>
                    <TestEmailForm setOpen={setOpen} />
                </Dialog.Content>
            </Dialog>
        </div>
    ) : null
}

export default AccountDevTools

type TestEmailFormProps = {
    setOpen: (open: boolean) => void
}

type EmailFormFields = {
    recipient: string
    subject: string
    body: string
}

function TestEmailForm({ setOpen }: TestEmailFormProps) {
    const { register, handleSubmit } = useForm<EmailFormFields>()
    const { useSendTestEmail, useAuthProfile } = useUserApi()
    const sendTestEmail = useSendTestEmail()
    const authUser = useAuthProfile()

    const onSubmit: SubmitHandler<EmailFormFields> = (data) => {
        if (authUser.data?.email !== data.recipient) {
            toast.error('You can only send test emails to yourself.')
            return
        }
        sendTestEmail.mutate(data)
        setOpen(false)
    }

    return (
        <form className="flex flex-col space-y-2" onSubmit={handleSubmit(onSubmit)}>
            <Input
                label="Recipient"
                defaultValue={authUser.data?.email ?? ''}
                {...register('recipient')}
            />
            <Input
                label="Subject"
                defaultValue="Test subject from Maybe"
                {...register('subject')}
            />
            <label>
                <div className="text-base text-gray-50 mb-1">Email body</div>
                <textarea
                    rows={4}
                    className="block w-full bg-gray-500 text-base placeholder:text-gray-100 rounded border-0 focus:ring-0 resize-none"
                    placeholder="Email body"
                    defaultValue="This is a test email from Maybe. If you are seeing this, it means that the email service is working correctly."
                    {...register('body')}
                    onKeyDown={(e) => e.key === 'Enter' && e.stopPropagation()}
                />
            </label>
            <Button type="submit">Send test email</Button>
        </form>
    )
}
