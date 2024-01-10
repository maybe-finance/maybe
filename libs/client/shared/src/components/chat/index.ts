import dynamic from 'next/dynamic'

// Dynamic import to avoid react-media-encoder errors (https://github.com/0x006F/react-media-recorder/issues/98)
export const MessageInput = dynamic(() => import('./MessageInput'), {
    ssr: false,
})

export * from './RichText'
export * from './AudioPlayer'
export * from './AudioVisualizer'
export * from './VideoPlayer'
export * from './Attachment'
export * from './UploadFile'
