import { type ReactNode, isValidElement } from 'react'

export function RenderValidChildren<F>({
    renderProps,
    children,
}: {
    renderProps: F
    children:
        | ReactNode
        | ((bag: F) => React.ReactElement<any, string | React.JSXElementConstructor<any>>)
}) {
    return typeof children === 'function' ? (
        children(renderProps)
    ) : isValidElement(children) ? (
        children
    ) : (
        <div></div>
    )
}
