'use client'

import { MaybeCard } from '@maybe-finance/client/shared'
import { type SharedType, superjson } from '@maybe-finance/shared'
import { Button, LoadingSpinner, Tooltip } from '@maybe-finance/design-system'
import Head from 'next/head'
import { useState } from 'react'
import { RiAnticlockwise2Line } from 'react-icons/ri'
import env from '../../../env'
import { NotFoundPage } from '@maybe-finance/client/features'

export default async function Card({ params: { id } }: { params: { id: string } }) {
    const [isFlipped, setIsFlipped] = useState(false)

    const rawData = await fetch(`${env.NEXT_PUBLIC_API_URL}/v1/users/card/${id}`).then((data) =>
        data.json()
    )

    if (!rawData.data) return <NotFoundPage />

    const data = superjson.deserialize(rawData.data) as SharedType.UserMemberCardDetails

    const title = data.name.trim()
        ? data.name
              .trim()
              .split(' ')
              .map((part, idx) => (idx > 0 ? part.substring(0, 1) : part))
              .join(' ') + "'s Maybe"
        : `Maybe Card #${data.memberNumber}`

    return (
        <>
            <Head>
                <title>{title}</title>
                <meta property="og:image" content={data.imageUrl} />
                <meta property="twitter:image" content={`${data.imageUrl}&twitter`} />
            </Head>
            <div className="fixed inset-0 flex flex-col items-center custom-gray-scroll pb-24">
                <a href="https://maybe.co" className="mt-12 md:mt-32 shrink-0">
                    <img src="/assets/maybe-full.svg" alt="Maybe" className="h-8" />
                </a>
                <div className="mt-8 w-[342px] sm:w-[406px] h-[464px] sm:h-[528px] shrink-0 flex justify-center items-center bg-gray-800 rounded-2xl overflow-hidden">
                    {data ? (
                        <MaybeCard variant="default" details={data} flipped={isFlipped} />
                    ) : (
                        <LoadingSpinner />
                    )}
                </div>
                <div className="mt-4 shrink-0">
                    <Tooltip content="Flip card" placement="bottom">
                        <div className="w-full">
                            <Button
                                type="button"
                                variant="secondary"
                                className="w-24"
                                onClick={() => setIsFlipped((flipped) => !flipped)}
                            >
                                <RiAnticlockwise2Line className="w-5 h-5 text-gray-50" />
                            </Button>
                        </div>
                    </Tooltip>
                </div>
            </div>
        </>
    )
}

Card.isPublic = true
