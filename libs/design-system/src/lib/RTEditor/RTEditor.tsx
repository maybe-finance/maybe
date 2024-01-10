import type { PropsWithChildren } from 'react'
import cn from 'classnames'
import { EditorContent, type Editor } from '@tiptap/react'
import {
    RiItalic,
    RiBold,
    RiStrikethrough,
    RiListOrdered,
    RiListUnordered,
    RiDoubleQuotesR,
    RiHeading,
} from 'react-icons/ri'

export type RTEditorProps = {
    editor: Editor | null
    className?: string
    hideControls?: boolean
}

export function RTEditor({ hideControls = false, editor, className }: RTEditorProps) {
    return (
        <>
            {!hideControls && <RichTextEditorMenuBar editor={editor} />}
            <EditorContent
                editor={editor}
                className={cn(
                    className,
                    'flex flex-col h-auto min-h-[80px] max-h-72 custom-gray-scroll border border-gray-700 rounded p-3 focus-within:border focus-within:border-cyan'
                )}
            />
        </>
    )
}

function RichTextEditorMenuBar({ editor }: { editor: Editor | null }) {
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
