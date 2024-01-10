import { useState, type FormEventHandler } from 'react'
import { useEditor, EditorContent } from '@tiptap/react'
import StarterKit from '@tiptap/starter-kit'
import Placeholder from '@tiptap/extension-placeholder'
import { RiAttachment2 } from 'react-icons/ri'
import type { Conversation } from '@prisma/client'
import type { O } from 'ts-toolbelt'
import { Button, Tooltip } from '@maybe-finance/design-system'
import { RichTextEditorMenuBar, UploadFile } from '@maybe-finance/client/shared'
import { trpc } from '../lib/trpc'
import Uppy from '@uppy/core'
import { DashboardModal, useUppy } from '@uppy/react'
import ScreenCapture from '@uppy/screen-capture'
import Webcam from '@uppy/webcam'
import UppyS3 from '@uppy/aws-s3'
import '@uppy/core/dist/style.css'
import '@uppy/dashboard/dist/style.css'
import '@uppy/screen-capture/dist/style.css'
import '@uppy/webcam/dist/style.css'

type MessageFormData = O.AtLeast<{
    body: string | null
    media: {
        fileId: string
        type: string
        key: string
    }
}>

export default function AdvisorMessageInput({
    conversationId,
    initialValue = {},
    onSubmit,
}: {
    conversationId: Conversation['id']
    initialValue?: Partial<MessageFormData>
    onSubmit(data: MessageFormData): Promise<any>
}) {
    const [showUploadModal, setShowUploadModal] = useState(false)

    // form state
    const [media, setMedia] = useState<MessageFormData['media']>(initialValue.media)
    const [isSubmitting, setIsSubmitting] = useState<boolean>(false)
    const [error, setError] = useState<string>()

    const editor = useEditor(
        {
            extensions: [
                StarterKit.configure({
                    heading: {
                        levels: [1],
                    },
                }),
                Placeholder.configure({
                    placeholder: 'Type message...',
                    emptyEditorClass: 'placeholder text-gray-100 caret-white',
                }),
            ],
            content: initialValue.body,
            editorProps: {
                attributes: {
                    class: 'flex-1 prose prose-light prose-sm dark:prose-invert prose-headings:text-lg leading-tight focus:outline-none',
                },
            },
        },
        [initialValue.body]
    )

    const signUrl = trpc.messages.signS3Url.useMutation()

    const uppy = useUppy(() =>
        new Uppy({ restrictions: { maxNumberOfFiles: 1 } })
            .use(ScreenCapture)
            .use(Webcam)
            .use(UppyS3, {
                getUploadParameters(file) {
                    return signUrl.mutateAsync({
                        conversationId,
                        mimeType: file.type,
                    })
                },
            })
    )

    uppy.on('upload-success', (file) => {
        if (!file?.meta?.key) throw new Error('Did not generate S3 key')
        if (!file?.type) throw new Error('No file type provided')

        setMedia({
            fileId: file.id,
            key: file.meta.key as string,
            type: file.type!,
        })
        setShowUploadModal(false)
    })

    const handleSubmit: FormEventHandler<HTMLFormElement> = (e) => {
        e.preventDefault()

        // TipTap defaults to `<p></p>` so we use `editor.isEmpty` to see if the user entered text or not
        const body = !editor || editor.isEmpty ? null : editor.getHTML()
        if (!body && !media) {
            setError(`Message or media upload is required`)
            return
        }

        setIsSubmitting(true)
        setError(undefined)

        onSubmit({ body, media })
            .then(() => {
                editor!.commands.clearContent()
                setMedia(undefined)
            })
            .catch((err) => {
                console.error('error submitting form', err)
                setError(`Error submitting form`)
            })
            .finally(() => setIsSubmitting(false))
    }

    return (
        <>
            <DashboardModal
                open={showUploadModal}
                onRequestClose={() => setShowUploadModal(false)}
                uppy={uppy}
                plugins={['ScreenCapture', 'Webcam']}
            />

            <form
                className="bg-gray-800 rounded-lg group border border-gray-800 focus-within:border-cyan w-full"
                onSubmit={handleSubmit}
            >
                {/* text toolbar */}
                <div className="px-2 pt-2 opacity-50 group-focus-within:opacity-100">
                    <RichTextEditorMenuBar editor={editor} />
                </div>

                {/* text editor */}
                <div className="px-4 pt-4 pb-1">
                    <EditorContent
                        editor={editor}
                        className="flex flex-col h-auto min-h-[48px] max-h-72 overflow-y-auto"
                    />
                </div>

                {/* upload thumbnails */}
                {media && (
                    <ul className="p-4 space-y-1">
                        <li className="border border-gray-500 bg-gray-700 rounded">
                            <UploadFile
                                name={media.key}
                                onClear={() => {
                                    uppy.removeFile(media.fileId)
                                    setMedia(undefined)
                                }}
                            />
                        </li>
                    </ul>
                )}

                {/* bottom bar */}
                <div className="px-4 pb-4 flex items-center justify-between space-x-2">
                    {/* action buttons */}
                    <div className="-ml-2 flex items-center space-x-1">
                        <Tooltip content="Attach file (max 10MB)">
                            <Button
                                type="button"
                                variant="icon"
                                onClick={() => setShowUploadModal(true)}
                            >
                                <RiAttachment2 size={20} className="text-gray-50" />
                            </Button>
                        </Tooltip>
                        {/* <Tooltip content="Record audio (max 10 min)">
                            <Button
                                type="button"
                                variant="icon"
                                onClick={() => console.debug('TODO')}
                            >
                                <RiMicLine size={20} className="text-gray-50" />
                            </Button>
                        </Tooltip> */}
                    </div>

                    {/* error message */}
                    {error && <p className="text-sm text-red">{error}</p>}

                    {/* submit */}
                    <Button variant="secondary" type="submit" disabled={isSubmitting}>
                        Send
                    </Button>
                </div>
            </form>
        </>
    )
}
