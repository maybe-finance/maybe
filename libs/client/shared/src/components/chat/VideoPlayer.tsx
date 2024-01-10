export type VideoPlayerProps = {
    src: string
}

export function VideoPlayer({ src }: VideoPlayerProps) {
    return <video controls src={src} className="rounded-lg" />
}
