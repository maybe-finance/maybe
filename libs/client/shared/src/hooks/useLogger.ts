import { useContext } from 'react'
import { LogProviderContext } from '../providers/LogProvider'

export const useLogger = () => {
    const logger = useContext(LogProviderContext)

    if (!logger) {
        throw new Error('Logger configured incorrectly')
    }

    return logger.logger
}
