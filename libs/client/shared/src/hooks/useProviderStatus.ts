import { useState } from 'react'

export function useProviderStatus() {
    const [isCollapsed, setIsCollapsed] = useState(false)

    return {
        isCollapsed,
        statusMessage: '',
        dismiss: () => setIsCollapsed(true),
        expand: () => setIsCollapsed(false),
    }
}
