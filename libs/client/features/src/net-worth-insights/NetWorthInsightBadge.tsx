import { Badge } from '@maybe-finance/design-system'
import type { InsightState } from '../insights'

export default function NetWorthInsightBadge({ variant }: { variant: InsightState }) {
    return variant === 'at-risk' ? (
        <Badge variant="red">At risk</Badge>
    ) : variant === 'review' ? (
        <Badge variant="warn">Review</Badge>
    ) : variant === 'healthy' ? (
        <Badge variant="teal">Healthy</Badge>
    ) : variant === 'excessive' ? (
        <Badge variant="warn">Excessive</Badge>
    ) : null
}
