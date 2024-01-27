import { RouterContext } from 'next/dist/shared/lib/router-context' // next 12
import '../styles.css'

import theme from './theme'

export const parameters = {
    docs: {
        theme,
    },
    nextRouter: {
        Provider: RouterContext.Provider,
    },
}
