import { ImageResponse } from '@vercel/og'
import { DateTime } from 'luxon'
import type { NextRequest } from 'next/server'

export const config = {
    runtime: 'experimental-edge',
}

const font = fetch(
    new URL('../../public/assets/fonts/inter/Inter-Regular.ttf', import.meta.url)
).then((res) => res.arrayBuffer())

const now = DateTime.now()

export default async function handler(req: NextRequest) {
    const fontData = await font

    try {
        const { searchParams } = new URL(req.url)
        const isTwitter = searchParams.has('twitter')
        const date = searchParams.get('date')

        return new ImageResponse(
            (
                <div
                    style={{
                        fontSize: 16,
                        lineHeight: '24px',
                        color: '#868E96',
                        background: '#1c1c20',
                        width: '100%',
                        height: '100%',
                        display: 'flex',
                        textAlign: 'center',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontFamily: '"Inter"',
                        transform: `scale(${isTwitter ? 1 : 1.5})`,
                    }}
                >
                    <div
                        style={{
                            width: '406px',
                            height: '528px',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                        }}
                    >
                        <img
                            alt=""
                            src="https://assets.maybe.co/images/maybe-card.png"
                            style={{ position: 'absolute', width: '100%' }}
                        />
                        <div
                            style={{
                                width: '276px',
                                height: '398px',
                                display: 'flex',
                                flexDirection: 'column',
                                justifyContent: 'flex-end',
                                alignItems: 'center',
                                padding: '24px',
                            }}
                        >
                            <span style={{ fontSize: 12, lineHeight: '16px' }}>
                                #{searchParams.get('number')?.padStart(3, '0') || '000'}
                            </span>
                            <span style={{ color: '#FFF', marginTop: '4px' }}>
                                {searchParams.get('name') || 'Maybe User'}
                            </span>
                            <span>{searchParams.get('title') || ' '}</span>
                            <span style={{ marginTop: '6px', fontSize: 12, lineHeight: '16px' }}>
                                Joined {(date ? DateTime.fromISO(date) : now).toFormat('LL.dd.yy')}
                            </span>
                        </div>
                    </div>
                </div>
            ),
            {
                width: 1200,
                height: isTwitter ? 628 : 1200,
                fonts: [
                    {
                        name: 'Inter',
                        data: fontData,
                        style: 'normal',
                    },
                ],
            }
        )
    } catch (e) {
        return new Response('Failed to generate image', { status: 500 })
    }
}
