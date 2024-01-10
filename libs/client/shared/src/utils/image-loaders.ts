import type { ImageLoaderProps } from 'next/legacy/image'

export function enhancerizerLoader({ src, width }: ImageLoaderProps): string {
    const parsed = JSON.parse(src) as { [key: string]: string | number }
    parsed.width ??= width
    parsed.height ??= width

    const queryString = Object.entries(parsed)
        .map((pair) => pair.map(encodeURIComponent).join('='))
        .join('&')

    return `https://enhancerizer.maybe.co/images?${queryString}`
}

export function s3Loader({ src }: Pick<ImageLoaderProps, 'src'>): string {
    return `https://assets.maybe.co/images/${src}`
}
