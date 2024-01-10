import { Tab as HeadlessTab } from '@headlessui/react'
import classNames from 'classnames'
import type { PropsWithChildren } from 'react'
import { useContext, useReducer, useRef, useEffect } from 'react'
import React, { createContext } from 'react'
import { RiCheckFill, RiCloseFill } from 'react-icons/ri'

type ExtractProps<T> = T extends React.ComponentType<infer P> ? P : T

const StepGroupContext = createContext({
    linear: true,
    groupComplete: false,
    selectedIndex: 0,
    steps: [] as HTMLElement[],
    registerStep: (element: HTMLElement) => {
        console.warn('Step registration failed', element)
    },
})

function Step({
    status: statusProp,
    className,
    children,
    ...rest
}: { status?: 'complete' | 'incomplete' | 'error'; disabled?: boolean } & ExtractProps<
    typeof HeadlessTab
>): JSX.Element {
    const { linear, selectedIndex, steps, registerStep, groupComplete } =
        useContext(StepGroupContext)
    const ref = useRef<HTMLElement>(null)

    useEffect(() => {
        if (ref.current) {
            registerStep(ref.current)
        }
    }, [registerStep])

    const index = ref.current ? steps.indexOf(ref.current) : -1

    const status = statusProp ?? (linear && index < selectedIndex ? 'complete' : 'incomplete')

    return (
        <HeadlessTab
            ref={ref}
            as={linear ? 'div' : 'button'}
            className={({ selected }) =>
                classNames(
                    className,
                    'flex items-center rounded-md font-medium text-base focus:outline-none',
                    !linear && 'focus:ring-2 focus:ring-gray-400 focus:ring-opacity-60',
                    groupComplete
                        ? 'text-teal'
                        : selected
                        ? 'text-cyan'
                        : {
                              complete: 'text-teal',
                              incomplete: 'text-white',
                              error: 'text-gray-100',
                          }[status]
                )
            }
            {...(rest as any)}
        >
            {({ selected }) => (
                <>
                    {index > 0 && <div className="mr-4 h-px w-6 bg-gray-500" />}
                    <span
                        className={classNames(
                            'flex items-center justify-center w-6 h-6 mr-3 text-sm rounded-md',
                            groupComplete
                                ? 'text-teal'
                                : selected
                                ? 'text-cyan bg-cyan bg-opacity-10'
                                : {
                                      complete: 'text-teal bg-teal bg-opacity-10',
                                      incomplete: 'text-gray-100 bg-gray-700',
                                      error: 'text-gray-800 bg-red',
                                  }[status]
                        )}
                    >
                        {groupComplete ? (
                            <RiCheckFill className="w-5 h-5" />
                        ) : (
                            {
                                complete: <RiCheckFill className="w-5 h-5 text-teal" />,
                                incomplete: index + 1,
                                error: <RiCloseFill className="w-5 h-5" />,
                            }[status]
                        )}
                    </span>
                    {children}
                </>
            )}
        </HeadlessTab>
    )
}

function registerStepReducer(state: HTMLElement[], stepElement: HTMLElement) {
    if (!state.includes(stepElement)) {
        return [...state, stepElement]
    }

    return state
}

function Group({
    linear = true,
    complete = false,
    currentStep,
    children,
    onChange,
    ...rest
}: { currentStep: number; linear?: boolean; complete?: boolean } & PropsWithChildren<
    Omit<ExtractProps<typeof HeadlessTab.Group>, 'selectedIndex' | 'children'>
>): JSX.Element {
    const [steps, registerStep] = useReducer(registerStepReducer, [])

    return (
        <HeadlessTab.Group
            selectedIndex={currentStep}
            onChange={(...args) => {
                if (!linear) onChange(...args)
            }}
            {...rest}
        >
            {({ selectedIndex }) => (
                <StepGroupContext.Provider
                    value={{
                        linear,
                        groupComplete: complete,
                        selectedIndex,
                        steps,
                        registerStep,
                    }}
                >
                    {children}
                </StepGroupContext.Provider>
            )}
        </HeadlessTab.Group>
    )
}

function List({ className, ...rest }: ExtractProps<typeof HeadlessTab.List>): JSX.Element {
    return (
        <HeadlessTab.List
            className={classNames(className, 'inline-flex items-center space-x-4')}
            {...rest}
        />
    )
}

function Panels({ className, ...rest }: ExtractProps<typeof HeadlessTab.Panels>): JSX.Element {
    return <HeadlessTab.Panels className={classNames(className)} {...rest} />
}

function Panel({ className, ...rest }: ExtractProps<typeof HeadlessTab.Panel>): JSX.Element {
    return <HeadlessTab.Panel className={classNames(className, 'focus:outline-none')} {...rest} />
}

export default Object.assign(Step, { Group, List, Panels, Panel })
