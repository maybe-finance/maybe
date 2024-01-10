import { Button } from '@maybe-finance/design-system'
import { useState } from 'react'
import { FeedbackDialog } from '../dialogs'

export function FeedbackButton() {
    const [isOpen, setIsOpen] = useState(false)

    return (
        <div className="mt-6 text-center">
            <Button onClick={() => setIsOpen(true)}>Send us your feedback</Button>
            <FeedbackDialog isOpen={isOpen} onClose={() => setIsOpen(false)} />
        </div>
    )
}
