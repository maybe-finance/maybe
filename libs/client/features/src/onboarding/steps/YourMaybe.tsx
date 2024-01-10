import { SCREEN, useScreenSize, useUserApi } from '@maybe-finance/client/shared'
import { Button, FractionalCircle } from '@maybe-finance/design-system'
import { useForm } from 'react-hook-form'
import {
    RiArrowRightLine,
    RiArtboard2Line,
    RiBankCardLine,
    RiBarChart2Line,
    RiBitCoinLine,
    RiBriefcaseLine,
    RiBuilding3Line,
    RiBuilding4Line,
    RiBuildingLine,
    RiCarLine,
    RiFlashlightLine,
    RiFlightTakeoffLine,
    RiHeartLine,
    RiHome5Line,
    RiHomeHeartLine,
    RiHomeLine,
    RiHomeSmile2Line,
    RiLineChartLine,
    RiOpenArmLine,
    RiPieChartLine,
    RiSailboatLine,
    RiScales2Line,
    RiStackLine,
    RiTrophyLine,
} from 'react-icons/ri'
import { AiOutlineLoading3Quarters as LoadingIcon } from 'react-icons/ai'
import type { StepProps } from './StepProps'
import { UserUtil } from '@maybe-finance/shared'

let suggestions = Object.entries({
    'Build a large and diverse investment portfolio': RiPieChartLine,
    'Start a coffee shop': RiBriefcaseLine,
    'Turn my side hustle into my own full-time business': RiBuildingLine,
    'Start a foundation to support charitable causes': RiStackLine,
    'Retire at age 40': RiFlashlightLine,
    'Start a gym': RiOpenArmLine,
    'Start an NFT gallery': RiArtboard2Line,
    'Buy my dream car': RiCarLine,
    'Pay off my loans so I can be debt free': RiScales2Line,
    "Save for my kid's college tuition": RiLineChartLine,
    'Save for my dream vacation': RiFlightTakeoffLine,
    'Start a museum': RiBuilding3Line,
    'Invest in real estate': RiHomeSmile2Line,
    'Buy a second home or vacation property': RiHomeHeartLine,
    'Save for a down payment on my first house': RiHomeLine,
    'Start a profitable agency': RiBuilding4Line,
    'Reach $5m with my business and retire': RiBarChart2Line,
    'Build an indie bootstrapped startup': RiBriefcaseLine,
    'Pay off all my credit card debt': RiBankCardLine,
    'Become an angel investor': RiTrophyLine,
    'Buy a sail boat and travel the world': RiSailboatLine,
    'Get married in Lake Como in Italy': RiHeartLine,
    'Build a modern cabin in the middle of the woods': RiHome5Line,
    'Build a crypto ETF': RiBitCoinLine,
    'Save for a round-the-world trip': RiFlightTakeoffLine,
})

// Duplicate suggestions to fill space better
suggestions = [...suggestions, ...suggestions]

const randoms = suggestions.map(() => [Math.random(), Math.random(), Math.random()])

const clamp = (num: number, min: number, max: number) => Math.min(Math.max(num, min), max)

export function YourMaybe({ title, onNext }: StepProps) {
    const screen = useScreenSize()

    const { useUpdateProfile } = useUserApi()
    const updateProfile = useUpdateProfile({ onSuccess: undefined })

    const {
        register,
        handleSubmit,
        formState: { isValid, isSubmitting },
        watch,
        setValue,
    } = useForm<{
        maybe: string
    }>({
        mode: 'onChange',
    })

    const maybe = watch('maybe')

    return (
        <>
            {screen === SCREEN.DESKTOP && (
                <div className="fixed top-0 left-0 w-screen h-screen flex items-center justify-center text-sm overflow-hidden">
                    {suggestions.map(([suggestion, Icon], idx) => {
                        const r = ((Math.PI * 2) / suggestions.length) * idx

                        return (
                            <div
                                key={idx}
                                className="absolute cursor-pointer select-none"
                                onClick={() =>
                                    setValue('maybe', suggestion, { shouldValidate: true })
                                }
                                style={{
                                    transform: `translateX(calc(${
                                        clamp(Math.sin(r), -0.5, 0.5) * 92
                                    }vw + ${randoms[idx][0] * 50 - 25}px)) translateY(calc(${
                                        Math.cos(r) * 47
                                    }vh + ${randoms[idx][1] * 30 - 15}px)) rotate(${
                                        randoms[idx][2] * 30 - 15
                                    }deg)`,
                                }}
                            >
                                <div
                                    className="max-w-[200px] p-px rounded-xl bg-gradient-to-b from-gray-800 to-gray-600 animate-float"
                                    style={{
                                        animationDelay: `-${randoms[idx][0] * 3}s`,
                                    }}
                                >
                                    <div className="flex items-center gap-3 p-3 bg-gradient-to-b from-gray-600 to-gray-800 rounded-xl">
                                        <Icon className="w-5 h-5 text-gray-100" />
                                        {suggestion}
                                    </div>
                                </div>
                            </div>
                        )
                    })}
                </div>
            )}
            <div className="relative w-full max-w-lg mx-auto mt-16 md:mt-[25vh]">
                <div className="flex justify-center">
                    <Fire />
                </div>
                <h2 className="mt-6 text-center">{title}</h2>
                <p className="mt-2 text-center text-base text-gray-50">
                    A maybe is a goal or dream you&rsquo;re considering, but have not yet fully
                    committed to because you&rsquo;re not yet sure if it&rsquo;s financially
                    feasible.
                </p>
                <form
                    onSubmit={handleSubmit(async (data) => {
                        await updateProfile.mutateAsync(data)
                        await onNext()
                    })}
                >
                    <div className="relative">
                        <textarea
                            rows={5}
                            className="mt-6 block w-full bg-gray-500 text-base placeholder:text-gray-100 rounded border-0 focus:ring-0 resize-none"
                            placeholder="What's your Maybe?"
                            {...register('maybe', { required: true })}
                            onKeyDown={(e) => e.key === 'Enter' && e.stopPropagation()}
                            maxLength={UserUtil.MAX_MAYBE_LENGTH}
                        />
                        <div className="absolute bottom-0 right-0 flex items-center gap-1 px-3 py-2">
                            <FractionalCircle
                                radius={6}
                                percent={((maybe?.length ?? 0) / UserUtil.MAX_MAYBE_LENGTH) * 100}
                            />
                            <span className="text-sm text-gray-50">
                                {240 - (maybe?.length ?? 0)}
                            </span>
                        </div>
                    </div>
                    <Button
                        type="submit"
                        fullWidth
                        className="mt-6"
                        disabled={!isValid || isSubmitting}
                    >
                        Submit my Maybe
                        {isSubmitting ? (
                            <LoadingIcon className="ml-2 w-5 h-5 animate-spin" />
                        ) : (
                            <RiArrowRightLine className="ml-2 w-5 h-5" />
                        )}
                    </Button>
                </form>
            </div>
        </>
    )
}

function Fire() {
    return (
        <svg
            width="51"
            height="56"
            viewBox="0 0 51 56"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
        >
            <path
                fillRule="evenodd"
                clipRule="evenodd"
                d="M32.3887 6.5807C32.2064 6.21552 31.9484 5.89332 31.632 5.63551C31.3156 5.37771 30.9479 5.1902 30.5534 5.08546C30.1589 4.98071 29.7467 4.96113 29.344 5.02801C28.9414 5.09489 28.5576 5.24669 28.2181 5.47334C27.2258 6.13488 26.4521 7.07829 25.8538 8.00445C25.2383 8.95362 24.6947 10.0552 24.2144 11.2144C23.2537 13.5269 22.4483 16.2996 21.7983 19.0781C21.0122 22.4735 20.4235 25.9116 20.0352 29.3751C18.8649 28.6206 17.9246 27.5589 17.3171 26.3061C16.3737 24.3502 16.1723 21.8939 16.1723 18.6725C16.1722 18.1037 16.0035 17.5477 15.6874 17.0749C15.3713 16.602 14.9222 16.2334 14.3967 16.0158C13.8712 15.7981 13.293 15.7412 12.7351 15.8521C12.1773 15.963 11.6648 16.2369 11.2626 16.639C9.39059 18.5069 7.90604 20.7263 6.89417 23.1696C5.88231 25.6128 5.36305 28.2319 5.36623 30.8765C5.36646 34.1874 6.18322 37.4472 7.74414 40.3671C9.30506 43.2869 11.562 45.7768 14.315 47.6161C17.068 49.4555 20.2321 50.5875 23.5271 50.9119C26.8221 51.2364 30.1462 50.7432 33.2051 49.4762C36.264 48.2091 38.9632 46.2072 41.0636 43.6479C43.1641 41.0885 44.6009 38.0506 45.2469 34.8033C45.8929 31.556 45.7281 28.1996 44.7671 25.0312C43.8061 21.8628 42.0786 18.9803 39.7375 16.639C38.0348 14.9391 36.9188 13.8059 35.8603 12.4195C34.8163 11.0504 33.7779 9.36205 32.3887 6.5807ZM31.5977 42.7267C30.391 43.9319 28.8542 44.7525 27.1814 45.0848C25.5085 45.4171 23.7748 45.2463 22.199 44.5938C20.6232 43.9413 19.2761 42.8365 18.3279 41.4189C17.3797 40.0013 16.8728 38.3345 16.8713 36.629C16.8713 36.629 19.3995 38.0671 24.0619 38.0671C24.0619 35.1909 25.5001 26.5621 27.6572 25.124C29.0954 28.0002 29.918 28.843 31.6006 30.5284C32.4032 31.3286 33.0397 32.2794 33.4736 33.3264C33.9075 34.3733 34.1302 35.4957 34.1288 36.629C34.1302 37.7623 33.9075 38.8847 33.4736 39.9316C33.0397 40.9786 32.4032 41.9294 31.6006 42.7295L31.5977 42.7267Z"
                fill="#1E1D23"
            />
            <path
                fillRule="evenodd"
                clipRule="evenodd"
                d="M32.3886 6.58171C32.2063 6.21652 31.9484 5.89432 31.6319 5.63652C31.3155 5.37871 30.9478 5.19121 30.5533 5.08646C30.1588 4.98172 29.7466 4.96214 29.3439 5.02901C28.9413 5.09589 28.5575 5.2477 28.218 5.47435C27.2257 6.13589 26.452 7.0793 25.8537 8.00546C25.2382 8.95462 24.6946 10.0562 24.2143 11.2154C23.2536 13.5279 22.4482 16.3006 21.7982 19.0791C21.6069 19.9054 21.4273 20.7342 21.2594 21.5653C21.0509 22.5977 20.8604 23.6335 20.6882 24.6724C20.6877 24.6755 20.6872 24.6786 20.6867 24.6817C20.4284 26.2402 20.2111 27.8055 20.0351 29.3761C18.8648 28.6216 17.9245 27.56 17.317 26.3071C16.6431 24.9099 16.3478 23.2573 16.2341 21.2529C16.1887 20.4514 16.1722 19.5937 16.1722 18.6735C16.1721 18.1047 16.0034 17.5487 15.6873 17.0759C15.3713 16.603 14.9221 16.2344 14.3966 16.0168C13.8711 15.7991 13.2929 15.7422 12.735 15.8531C12.1772 15.964 11.6647 16.2379 11.2625 16.64C9.39049 18.5079 7.90595 20.7273 6.89408 23.1706C5.88221 25.6139 5.36296 28.233 5.36613 30.8775C5.36637 34.1884 6.18312 37.4482 7.74405 40.3681C9.30497 43.2879 11.5619 45.7778 14.3149 47.6172C17.0679 49.4565 20.232 50.5885 23.527 50.913C26.822 51.2374 30.1462 50.7442 33.205 49.4772C36.2639 48.2101 38.9631 46.2082 41.0636 43.6489C43.164 41.0895 44.6008 38.0516 45.2468 34.8043C45.8928 31.5571 45.728 28.2006 44.767 25.0322C43.806 21.8638 42.0785 18.9813 39.7374 16.64C38.0347 14.9401 36.9187 13.8069 35.8603 12.4205C34.8162 11.0514 33.7778 9.36305 32.3886 6.58171ZM24.6555 32.9527C24.2909 34.9219 24.0817 36.7853 24.0632 37.9101C24.0623 37.9646 24.0618 38.0173 24.0618 38.0681C23.3686 38.0681 22.7225 38.0363 22.1249 37.9822C20.9061 37.8718 19.8889 37.6684 19.0844 37.4524C17.6305 37.0619 16.8712 36.63 16.8712 36.63C16.8727 38.3355 17.3796 40.0023 18.3278 41.4199C18.6148 41.849 18.9383 42.2494 19.2936 42.6172C20.1124 43.4648 21.1 44.1398 22.1989 44.5948C23.7747 45.2473 25.5084 45.4181 27.1813 45.0858C28.8541 44.7535 30.3909 43.9329 31.5976 42.7277L31.6005 42.7306C31.6066 42.7244 31.6128 42.7183 31.6189 42.7122C31.6782 42.6527 31.7367 42.5923 31.7942 42.5311C32.5059 41.7741 33.0751 40.8939 33.4735 39.9326C33.7209 39.3357 33.8996 38.7142 34.0073 38.0802C34.0885 37.6023 34.1293 37.1171 34.1287 36.63C34.1301 35.4967 33.9074 34.3743 33.4735 33.3274C33.0396 32.2804 32.4031 31.3296 31.6005 30.5295C31.2584 30.1868 30.9519 29.879 30.6685 29.5818C29.558 28.4173 28.8029 27.4165 27.6572 25.125C26.6257 25.8126 25.7587 28.1441 25.1346 30.7048C24.9539 31.4463 24.7935 32.2071 24.6555 32.9527ZM29.0991 37.1726C29.1096 37.049 29.1219 36.9181 29.1359 36.7807C29.1307 36.9121 29.1185 37.0429 29.0991 37.1726ZM0.375991 30.8805C0.372419 27.5798 1.02071 24.3108 2.28367 21.2612C3.54683 18.2111 5.39997 15.4406 7.73671 13.1086C7.73704 13.1083 7.73737 13.108 7.73771 13.1076C8.83734 12.0096 10.2376 11.2619 11.7618 10.9588C13.2875 10.6554 14.8689 10.8112 16.3061 11.4064C17.0629 11.7199 17.7617 12.1477 18.3801 12.6714C18.7528 11.5083 19.1602 10.3743 19.6043 9.30502C19.6044 9.30465 19.6046 9.30428 19.6047 9.30391C20.1583 7.96811 20.8345 6.57438 21.6656 5.29236C22.4565 4.06888 23.67 2.50982 25.447 1.32427C25.4475 1.32393 25.4481 1.32359 25.4486 1.32325C25.449 1.32293 25.4495 1.32262 25.45 1.3223C26.3776 0.703522 27.4262 0.289026 28.5263 0.106314C29.6275 -0.0765912 30.755 -0.0230311 31.8339 0.263438C32.9128 0.549906 33.9184 1.06272 34.7838 1.7678C35.649 2.47266 36.3543 3.35353 36.8528 4.35189C36.853 4.35221 36.8532 4.35252 36.8533 4.35284C38.1587 6.96618 39.0376 8.35749 39.8265 9.39231M0.375991 30.8805C0.376729 35.0111 1.39589 39.0779 3.34327 42.7206C5.29107 46.3642 8.10736 49.4712 11.5427 51.7664C14.978 54.0616 18.9264 55.4742 23.038 55.8791C27.1497 56.2839 31.2977 55.6686 35.1147 54.0875C38.9317 52.5063 42.2999 50.0083 44.921 46.8146C47.542 43.6209 49.335 39.8301 50.1411 35.778C50.9472 31.7258 50.7415 27.5375 49.5424 23.5838C48.3432 19.6301 46.1875 16.0332 43.2662 13.1116L43.263 13.1084C41.535 11.3833 40.6521 10.4736 39.8268 9.39261"
                fill="url(#paint0_linear_881_33987)"
            />
            <path
                d="M24.6554 32.9167C24.2908 34.8859 24.0816 36.7494 24.0631 37.8742C24.0622 37.9286 24.0617 37.9813 24.0617 38.0322C23.3685 38.0322 22.7224 38.0004 22.1249 37.9462C20.906 37.8358 19.8888 37.6325 19.0843 37.4164C17.6305 37.026 16.8711 36.594 16.8711 36.594C16.8726 38.2995 17.3795 39.9664 18.3277 41.384C18.6147 41.813 18.9382 42.2134 19.2936 42.5812C20.1123 43.4289 21.0999 44.1038 22.1988 44.5588C23.7746 45.2113 25.5084 45.3822 27.1812 45.0498C28.854 44.7175 30.3908 43.8969 31.5975 42.6917L31.6004 42.6946C31.6066 42.6885 31.6127 42.6824 31.6188 42.6762C31.6782 42.6167 31.7366 42.5563 31.7942 42.4951C32.5059 41.7381 33.0751 40.8579 33.4734 39.8966C33.7208 39.2997 33.8995 38.6783 34.0072 38.0443C34.0884 37.5663 34.1292 37.0812 34.1287 36.594C34.13 35.4607 33.9073 34.3384 33.4734 33.2914C33.0395 32.2445 32.403 31.2936 31.6004 30.4935C31.2584 30.1508 30.9518 29.843 30.6684 29.5458C29.5579 28.3813 28.8028 27.3805 27.6571 25.089C26.6256 25.7766 25.7586 28.1082 25.1345 30.6688C24.9538 31.4103 24.7934 32.1711 24.6554 32.9167Z"
                fill="#F4F4F4"
            />
            <defs>
                <linearGradient
                    id="paint0_linear_881_33987"
                    x1="28.7387"
                    y1="6.68036"
                    x2="52.5632"
                    y2="45.3738"
                    gradientUnits="userSpaceOnUse"
                >
                    <stop stopColor="#4CC9F0" />
                    <stop offset="0.28684" stopColor="#4361EE" />
                    <stop offset="0.524848" stopColor="#7209B7" />
                    <stop offset="0.83892" stopColor="#F72585" />
                </linearGradient>
            </defs>
        </svg>
    )
}
