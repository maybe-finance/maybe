import type { ReactElement, ReactHTML, ReactNode } from 'react'

export type WithChildrenRenderProps<Props, RenderProps> = Props & {
    children?: ReactNode | ((props: RenderProps) => ReactElement)
}
