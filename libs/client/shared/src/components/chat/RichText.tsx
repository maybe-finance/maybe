import type { PropsWithChildren } from 'react'
import cn from 'classnames'
import { useEditor, EditorContent, type Editor } from '@tiptap/react'
import StarterKit from '@tiptap/starter-kit'
import {
    RiItalic,
    RiBold,
    RiStrikethrough,
    RiListOrdered,
    RiListUnordered,
    RiDoubleQuotesR,
    RiHeading,
} from 'react-icons/ri'

type Props = {
    text?: string | null
    className?: string
}

export function RichText({
    text,
    className = 'max-w-none prose prose-light prose-sm dark:prose-invert prose-headings:text-lg leading-tight focus:outline-none',
}: Props) {
    const editor = useEditor(
        {
            extensions: [
                StarterKit.configure({
                    heading: {
                        levels: [1],
                    },
                }),
            ],
            content: text,
            editable: false,
            editorProps: {
                attributes: {
                    class: className,
                },
            },
        },
        [text]
    )

    return <EditorContent editor={editor} />
}

export function useRichTextPreview(text?: string | null) {
    const editor = useEditor(
        {
            extensions: [StarterKit],
            content: text,
        },
        [text]
    )

    return editor?.getText()
}

export function RichTextEditorMenuBar({ editor }: { editor: Editor | null }) {
    if (!editor) return null

    return (
        <div className="flex items-center space-x-2">
            <div className="flex space-x-0.5">
                <MenuButton editor={editor} mark="bold" tooltip="Bold">
                    <RiBold size={16} />
                </MenuButton>
                <MenuButton editor={editor} mark="italic" tooltip="Italicize">
                    <RiItalic size={16} />
                </MenuButton>
                <MenuButton editor={editor} mark="strike" tooltip="Strikethrough">
                    <RiStrikethrough size={16} />
                </MenuButton>
            </div>
            <div className="pl-2 border-l flex space-x-0.5">
                <MenuButton editor={editor} mark="orderedList" tooltip="Numbered list">
                    <RiListOrdered size={16} />
                </MenuButton>
                <MenuButton editor={editor} mark="bulletList" tooltip="Bulleted List">
                    <RiListUnordered size={16} />
                </MenuButton>
            </div>
            <div className="pl-2 border-l flex space-x-0.5">
                <MenuButton
                    editor={editor}
                    mark="heading"
                    attributes={{ level: 1 }}
                    tooltip="Heading"
                >
                    <RiHeading size={16} />
                </MenuButton>
                <MenuButton editor={editor} mark="blockquote" tooltip="Blockquote">
                    <RiDoubleQuotesR size={16} />
                </MenuButton>
            </div>
        </div>
    )
}

function MenuButton({
    editor,
    mark,
    attributes,
    tooltip,
    children,
}: PropsWithChildren<{ editor: Editor; mark: string; attributes?: any; tooltip?: string }>) {
    const method = `toggle${mark[0].toUpperCase()}${mark.slice(1)}`
    return (
        <button
            type="button"
            title={tooltip}
            onClick={() => (editor.chain().focus() as any)[method](attributes).run()}
            disabled={!(editor.can().chain().focus() as any)[method](attributes).run()}
            className={cn(
                'p-1.5 text-base text-gray-100 leading-none rounded hover:bg-gray-600',
                editor.isActive(mark) ? 'bg-gray-600' : ''
            )}
        >
            {children}
        </button>
    )
}
