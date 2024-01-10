import { type FormEventHandler, useRef, useState } from 'react'
import { RiAttachment2, RiMicLine } from 'react-icons/ri'
import { AiOutlineLoading3Quarters as LoadingIcon } from 'react-icons/ai'
import toast from 'react-hot-toast'
import { useReactMediaRecorder } from 'react-media-recorder'
import { Button, Tooltip } from '@maybe-finance/design-system'
import { useEditor, EditorContent } from '@tiptap/react'
import StarterKit from '@tiptap/starter-kit'
import Placeholder from '@tiptap/extension-placeholder'
import { AudioPlayer } from './AudioPlayer'
import { motion } from 'framer-motion'
import { AudioVisualizer } from './AudioVisualizer'
import { DateTime, Duration } from 'luxon'
import { useInterval } from '../../hooks'
import { UploadFile, RichTextEditorMenuBar } from '../..'
import type { Message } from '@prisma/client'
import { ATAUtil } from '@maybe-finance/shared'

export type MessageInputProps = {
    placeholder?: string
    disabled?: boolean
    onSubmit(data: Pick<Message, 'type'> & { body: string; attachment: File | null }): Promise<any>
}

export default function MessageInput({
    placeholder = 'Send a message',
    disabled = false,
    onSubmit,
}: MessageInputProps) {
    const fileRef = useRef<HTMLInputElement | null>(null)
    const [recordingCanceled, setRecordingCanceled] = useState(false)
    const [recordingStartTime, setRecordingStartTime] = useState<DateTime | undefined>()
    const [recordingSeconds, setRecordingSeconds] = useState<number>()

    // form state
    const [isSubmitting, setIsSubmitting] = useState(false)
    const [attachment, setAttachment] = useState<File | null>(null)

    const editor = useEditor(
        {
            extensions: [
                StarterKit.configure({
                    heading: {
                        levels: [1],
                    },
                }),
                Placeholder.configure({
                    placeholder,
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

    const {
        status,
        startRecording: recorderStartRecording,
        stopRecording,
        mediaBlobUrl: recorderMediaBlobUrl,
        clearBlobUrl,
        previewAudioStream,
    } = useReactMediaRecorder({
        audio: true,
        onStop: (_, blob) => {
            if (recordingCanceled) return
            setAttachment(
                new File([blob], `audio-recording-${Date.now()}`, {
                    type: blob.type,
                })
            )
        },
    })

    const startRecording = () => {
        setRecordingCanceled(false)
        clearBlobUrl()
        recorderStartRecording()
        setRecordingSeconds(0)
        setRecordingStartTime(DateTime.now())
    }

    const isRecording = status === 'recording'

    const mediaBlobUrl = recordingCanceled ? null : recorderMediaBlobUrl

    const clearAttachments = () => {
        clearBlobUrl()
        setAttachment(null)
        if (fileRef.current?.value) {
            fileRef.current.value = ''
        }
    }

    useInterval(() => {
        if (recordingStartTime && isRecording)
            setRecordingSeconds(Math.abs(recordingStartTime.diffNow('seconds').seconds))
    }, 1000)

    const handleSubmit: FormEventHandler<HTMLFormElement> = (e) => {
        e.preventDefault()

        // TipTap defaults to `<p></p>` so we use `editor.isEmpty` to see if the user entered text or not
        const body = !editor || editor.isEmpty ? '' : editor.getHTML()
        if (!body && !attachment) {
            toast(`Message or media upload is required`)
            return
        }

        setIsSubmitting(true)

        onSubmit({
            type: attachment ? ATAUtil.mimeToMessageType(attachment.type) : 'text',
            body,
            attachment: attachment,
        })
            .then(() => {
                editor?.commands.clearContent()
                clearAttachments()
            })
            .catch((err) => {
                toast.error('Error sending message')
                console.error('error sending message', err)
            })
            .finally(() => setIsSubmitting(false))
    }

    return (
        <form
            className="bg-gray-800 rounded-lg group border border-gray-800 focus-within:border-cyan w-full"
            onSubmit={handleSubmit}
        >
            {isRecording ? (
                <motion.div
                    initial={{ height: 64 }}
                    animate={{ height: 106 }}
                    transition={{ ease: 'linear' }}
                    className="flex justify-center items-center space-x-4 mb-4 p-4 bg-gray-700 rounded-lg overflow-hidden"
                >
                    <div className="grow h-[74px] max-w-lg">
                        {previewAudioStream && <AudioVisualizer stream={previewAudioStream} />}
                    </div>
                    {recordingStartTime && (
                        <span className="tabular-nums">
                            {Duration.fromObject({ seconds: recordingSeconds }).toFormat('mm:ss')}
                        </span>
                    )}
                </motion.div>
            ) : (
                <>
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
                </>
            )}

            {/* upload thumbnails */}
            {attachment && (
                <ul className="p-4 space-y-1">
                    <li className="border border-gray-500 bg-gray-700 rounded">
                        {mediaBlobUrl ? (
                            <AudioPlayer
                                variant="upload"
                                src={mediaBlobUrl}
                                duration={recordingSeconds}
                                onClose={clearAttachments}
                            />
                        ) : (
                            <UploadFile name={attachment.name} onClear={clearAttachments} />
                        )}
                    </li>
                </ul>
            )}

            {/* bottom bar */}
            <div className="px-4 pb-4 flex items-center justify-between space-x-2">
                {isRecording ? (
                    <div className="grow flex items-center justify-end space-x-2">
                        <Button
                            variant="secondary"
                            onClick={() => {
                                setRecordingCanceled(true)
                                stopRecording()
                            }}
                        >
                            Cancel
                        </Button>
                        <Button variant="secondary" onClick={() => stopRecording()}>
                            Stop
                        </Button>
                    </div>
                ) : (
                    <>
                        {/* action buttons */}
                        <div className="-ml-2 flex items-center space-x-1">
                            <Tooltip content="Attach file (max 10MB)">
                                <Button
                                    variant="icon"
                                    disabled={disabled || !!attachment}
                                    onClick={() => {
                                        fileRef.current?.click()
                                    }}
                                >
                                    <RiAttachment2 size={20} className="text-gray-50" />
                                    <input
                                        ref={fileRef}
                                        type="file"
                                        className="hidden"
                                        onChange={(e) => {
                                            if (e.target.files?.length) {
                                                const f = e.target.files[0]

                                                // Throw error if file is greater than 10MB (server also validates this as fallback)
                                                if (f.size >= 1_000_000 * 10) {
                                                    toast.error('File must be 10MB or less')
                                                    clearAttachments()
                                                } else {
                                                    setAttachment(e.target.files[0])
                                                }
                                            }
                                        }}
                                    />
                                </Button>
                            </Tooltip>
                            <Tooltip content="Record audio (max 10 min)">
                                <Button
                                    variant="icon"
                                    disabled={disabled || !!attachment}
                                    onClick={() => startRecording()}
                                >
                                    {status === 'acquiring_media' ? (
                                        <LoadingIcon
                                            size={16}
                                            className="text-gray-50 animate-spin"
                                        />
                                    ) : (
                                        <RiMicLine size={20} className="text-gray-50" />
                                    )}
                                </Button>
                            </Tooltip>
                        </div>

                        {/* submit */}
                        <Button
                            type="submit"
                            className={isSubmitting ? 'animate-pulse' : ''}
                            variant="secondary"
                            disabled={disabled || isSubmitting}
                        >
                            {isSubmitting
                                ? attachment != null
                                    ? 'Uploading media...'
                                    : 'Sending'
                                : 'Send'}
                        </Button>
                    </>
                )}
            </div>
        </form>
    )
}
