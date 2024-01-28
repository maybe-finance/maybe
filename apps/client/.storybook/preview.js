import '../styles.css'
import { RouterContext } from 'next/dist/shared/lib/router-context'

import theme from './theme'

export const parameters = {
    docs: {
        theme,
    },
    nextRouter: {
        Provider: RouterContext.Provider,
    },
}
