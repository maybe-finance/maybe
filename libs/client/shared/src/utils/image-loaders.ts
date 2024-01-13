import type { ImageLoaderProps } from 'next/legacy/image'

function isJSON(str: string): boolean {
    try {
        JSON.parse(str)
        return true
    } catch (e) {
        return false
    }
}

export function enhancerizerLoader({ src, width }: ImageLoaderProps): string {
    let parsed: { [key: string]: string | number }

    if (isJSON(src)) {
        parsed = JSON.parse(src)
    } else {
        parsed = { src }
    }

    parsed.width ??= width
    parsed.height ??= width

    const queryString = Object.entries(parsed)
        .map((pair) => pair.map(encodeURIComponent).join('='))
        .join('&')

    return `https://enhancerizer.maybe.co/images?${queryString}`
}
