import { useEffect, useState } from 'react'
import { DateTime } from 'luxon'

export default function RelativeTime({ time }: { time: Date | DateTime }) {
    const dateTime = DateTime.isDateTime(time) ? time : DateTime.fromJSDate(time)

    const [now, setNow] = useState(DateTime.now())

    useEffect(() => {
        const interval = setInterval(() => setNow(DateTime.now()), 60_000)
        return () => clearInterval(interval)
    }, [])

    return (
        <time dateTime={dateTime.toISO()} title={dateTime.toLocaleString(DateTime.DATETIME_FULL)}>
            {Math.abs(dateTime.diff(now, 'minutes').as('minutes')) < 1
                ? 'Just now'
                : dateTime.toRelative({ base: now })}
        </time>
    )
}
