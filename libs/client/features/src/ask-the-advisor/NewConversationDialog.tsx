import { useRouter } from 'next/router'
import { useForm } from 'react-hook-form'
import classNames from 'classnames'
import toast from 'react-hot-toast'
import { EditorContent, useEditor } from '@tiptap/react'
import Placeholder from '@tiptap/extension-placeholder'
import StarterKit from '@tiptap/starter-kit'
import type { Account, Plan } from '@prisma/client'
import { useConversationApi } from '@maybe-finance/client/shared'
import { Button, DialogV2, Input } from '@maybe-finance/design-system'

type NewConversationDialogProps = {
    title?: string
    open: boolean
    onClose: () => void
    accountId?: Account['id']
    planId?: Plan['id']
}

export function NewConversationDialog({
    title,
    open,
    onClose,
    accountId,
    planId,
}: NewConversationDialogProps) {
    const router = useRouter()
    const { useCreateConversation } = useConversationApi()

    const createConversation = useCreateConversation({
        onSuccess(conversation) {
            toast.success(`Question submitted!`)

            router.push(`/ask-the-advisor/${conversation.id}`)
        },
    })

    return (
        <DialogV2 title="Anything to add on?" open={open} onClose={onClose} className="text-base">
            {open && (
                <NewConversationForm
                    initialValues={title ? { title } : undefined}
                    onSubmit={({ title, body }) =>
                        createConversation.mutateAsync({
                            title,
                            initialMessage: body
                                ? {
                                      type: 'text', // TODO: handle audio and video
                                      body,
                                  }
                                : undefined,
                            accountId,
                            planId,
                        })
                    }
                />
            )}
        </DialogV2>
    )
}

function NewConversationForm({
    initialValues,
    onSubmit,
}: {
    initialValues?: Partial<{ title: string }>
    onSubmit(data: { title: string; body: string | null }): Promise<any>
}) {
    // new question form state
    const { register, handleSubmit, formState } = useForm<{ title: string }>({
        defaultValues: initialValues,
    })

    const editor = useEditor(
        {
            extensions: [
                StarterKit.configure({
                    heading: {
                        levels: [1],
                    },
                }),
                Placeholder.configure({
                    placeholder:
                        'e.g. I have a spouse and 2 children, so any advice I receive will need to take that into consideration',
                    emptyEditorClass: 'placeholder text-gray-100 caret-white',
                }),
            ],
            editorProps: {
                attributes: {
                    class: 'flex-1 prose prose-light prose-sm dark:prose-invert prose-headings:text-lg leading-tight focus:outline-none',
                },
            },
        },
        []
    )

    return (
        <form
            onSubmit={handleSubmit(({ title }) =>
                onSubmit({
                    title,
                    body: !editor || editor.isEmpty ? null : editor.getHTML(),
                })
            )}
        >
            <p className="text-gray-50">
                Feel free to add more context to your question to make sure the advisor has the full
                picture before answering.
            </p>

            <div className="mt-2">
                <Input
                    type="text"
                    {...register('title', { required: true })}
                    required
                    fixedLeftOverride="Q:"
                />
            </div>

            <div className="mt-2">
                <EditorContent
                    editor={editor}
                    className="px-3 py-2 rounded flex flex-col h-auto min-h-[144px] max-h-72 overflow-y-auto bg-gray-500 border border-transparent focus-within:border-cyan focus-within:ring focus-within:ring-cyan focus-within:ring-opacity-10"
                />
            </div>

            <p className="mt-2 text-gray-100 text-sm">
                This is optional but it helps our advisors out.
            </p>

            <Button
                type="submit"
                fullWidth
                className={classNames('mt-6', formState.isSubmitting && 'animate-pulse')}
                disabled={!formState.isValid || formState.isSubmitting}
            >
                {formState.isSubmitting ? 'Redirecting to conversation...' : 'Submit question'}
            </Button>
        </form>
    )
}
