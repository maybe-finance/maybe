import { useSession } from 'next-auth/react'
import { Button, Dialog } from '@maybe-finance/design-system'
import { useState } from 'react'
import axios from 'axios'
import toast from 'react-hot-toast'

export interface FeedbackDialogProps {
    isOpen: boolean
    onClose: () => void
    notImplementedNotice?: boolean
}

export function FeedbackDialog({ isOpen, onClose, notImplementedNotice }: FeedbackDialogProps) {
    const [feedback, setFeedback] = useState('')
    const { data: session } = useSession()

    return (
        <Dialog isOpen={isOpen} onClose={onClose}>
            <Dialog.Title>Send us your feedback!</Dialog.Title>
            <Dialog.Content>
                {notImplementedNotice ? (
                    <p className="text-sm text-white mb-6">
                        This feature has not been implemented yet, but is coming soon! Mind helping
                        us out and telling us what you want with this particular feature below?
                    </p>
                ) : (
                    <p className="text-sm text-gray-100 mb-6">
                        Maybe is built in public and relies heavily on user feedback. We'd love to
                        hear what you think could be better (please be constructive, we're still in
                        the early days!{' '}
                        <span role="img" aria-label="happy emoji">
                            😄
                        </span>
                        )
                    </p>
                )}
                <form
                    onSubmit={async (e) => {
                        e.preventDefault()

                        try {
                            await axios
                                .create({ transformRequest: [(data) => JSON.stringify(data)] })
                                .post('https://hooks.zapier.com/hooks/catch/10143005/buyo6na/', {
                                    comment: `**From user:** ${session?.user?.email}\n\n${feedback}`,
                                    page: `**Main app feedback**: ${window.location.href}`,
                                })

                            toast.success('Your feedback was submitted!')
                        } catch (e) {
                            toast.error('Feedback not submitted')
                        }

                        onClose()
                    }}
                >
                    <textarea
                        value={feedback}
                        onChange={(e) => setFeedback(e.target.value)}
                        className="w-full rounded bg-gray-500 text-base border-0 focus:ring focus:ring-opacity-60 focus:ring-cyan"
                        rows={6}
                    ></textarea>
                    <Button className="mt-4" type="submit" disabled={feedback.length < 10}>
                        Submit
                    </Button>
                </form>
            </Dialog.Content>
        </Dialog>
    )
}
