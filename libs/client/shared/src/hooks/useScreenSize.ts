import { useMediaQuery } from 'react-responsive'

// Starting very simple, will likely add a Tablet designation in the future
export enum SCREEN {
    MOBILE = 'MOBILE',
    DESKTOP = 'DESKTOP',
}

export const useScreenSize = (cb?: () => void): SCREEN => {
    // TODO: find a way to get breakpoint from Tailwind config
    const isDesktop = useMediaQuery({ query: `(min-width: 1024px)` }, undefined, cb)

    return isDesktop ? SCREEN.DESKTOP : SCREEN.MOBILE
}
