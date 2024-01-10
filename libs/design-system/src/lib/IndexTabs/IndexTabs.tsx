import { useCallback, useEffect, useRef, useState } from 'react'
import type { RefObject, HTMLAttributes } from 'react'
import scrollIntoView from 'smooth-scroll-into-view-if-needed'
import classNames from 'classnames'
import { animate } from 'framer-motion'

export interface IndexTabsProps extends HTMLAttributes<HTMLElement> {
    sections: {
        name: string
        elementRef: RefObject<HTMLElement>
    }[]
    scrollContainer: RefObject<HTMLElement>
    initialIndex?: number
}

export default function IndexTabs({
    className,
    sections,
    scrollContainer,
    initialIndex,
    ...rest
}: IndexTabsProps): JSX.Element {
    // The active tab's index
    const [activeIndex, setActiveIndex] = useState<number | null>(0)

    // The index being automatically scrolled to
    const [scrollingTo, setScrollingTo] = useState<number | null>(null)

    const tabElements = useRef<(HTMLElement | null)[]>([])

    useEffect(() => {
        if (!scrollContainer.current) return
        const scrollElement = scrollContainer.current
        let scrollTimeout: NodeJS.Timeout | undefined = undefined

        const onScroll = () => {
            // Find the first visible section
            let index: number | null = sections.findIndex(({ elementRef }) => {
                const elementRect = elementRef.current?.getBoundingClientRect()
                const parentRect = elementRef.current?.parentElement?.getBoundingClientRect()
                if (!elementRect || !parentRect) return false

                return elementRect.top <= parentRect.top
                    ? parentRect.top - elementRect.top < elementRect.height
                    : elementRect.bottom - parentRect.bottom < elementRect.height
            })
            index = index !== -1 ? index : null

            // Only update active tab if we're not automatically scrolling or we're finished scrolling
            if (scrollingTo === null || scrollingTo === index) {
                setActiveIndex(index)
                setScrollingTo(null)
            }

            // Reset scrollingTo after 100 ms of not scrolling
            clearTimeout(scrollTimeout)
            scrollTimeout = setTimeout(function () {
                setScrollingTo(null)
            }, 100)
        }

        scrollElement.addEventListener('scroll', onScroll)

        return () => scrollElement.removeEventListener('scroll', onScroll)
    }, [scrollContainer, scrollingTo, sections])

    const scrollTo = useCallback(
        (index: number) => {
            const elementRef = sections[index].elementRef
            if (!elementRef.current) return

            scrollIntoView(elementRef.current, {
                behavior: 'smooth',
                block: 'start',
                inline: 'nearest',
            })

            // Blink heading if the container is not scrollable
            if (
                scrollContainer.current &&
                scrollContainer.current.clientHeight === scrollContainer.current.scrollHeight
            ) {
                const el = elementRef.current

                animate(1, [1, 0.6, 1, 0.6, 1], {
                    duration: 0.5,
                    onUpdate: (value) => {
                        const heading = el.querySelector<HTMLElement>('h1, h2, h3, h4, h5, h6')
                        if (heading) heading.style.opacity = value.toString()
                    },
                })
            }

            setScrollingTo(index)
            setActiveIndex(index)
        },
        [sections, scrollContainer]
    )

    useEffect(() => {
        if (initialIndex) {
            scrollTo(initialIndex)
        }
    }, [scrollTo, initialIndex])

    useEffect(() => {
        if (activeIndex !== null) {
            const tabElement = tabElements.current[activeIndex]
            tabElement &&
                scrollIntoView(tabElement, {
                    behavior: 'smooth',
                    block: 'nearest',
                    inline: 'nearest',
                })
        }
    }, [activeIndex, tabElements])

    return (
        <nav
            className={classNames(
                className,
                'relative flex gap-2 w-full overflow-x-scroll scrollbar-none text-base'
            )}
            {...rest}
        >
            {sections.map(({ name }, index) => (
                <button
                    ref={(el) => (tabElements.current[index] = el)}
                    key={name + index}
                    className={classNames(
                        'py-1 px-2 rounded-md whitespace-nowrap',
                        'hover:bg-gray-600 transition',
                        index === activeIndex ? 'text-white bg-gray-500' : 'text-gray-100'
                    )}
                    onClick={() => scrollTo(index)}
                >
                    {name}
                </button>
            ))}
        </nav>
    )
}
