import type { ReactNode } from 'react'
import { Button, FractionalCircle } from '@maybe-finance/design-system'
import classNames from 'classnames'
import { useForm } from 'react-hook-form'
import {
    RiAlertLine,
    RiCoinLine,
    RiLineChartLine,
    RiOpenArmLine,
    RiParentLine,
    RiPercentLine,
    RiScales3Line,
    RiWallet3Line,
} from 'react-icons/ri'
import { QuestionTag } from './QuestionTag'

export type QuestionCategory =
    | 'tax'
    | 'portfolio'
    | 'budgeting'
    | 'debt'
    | 'risk'
    | 'retirement'
    | 'saving'
    | 'estate'

type QuestionTag = {
    key: QuestionCategory
    tag: ReactNode
}

const questions: QuestionTag[] = [
    {
        key: 'tax',
        tag: <QuestionTag text="US Tax" iconClassName="text-red" icon={RiPercentLine} />,
    },
    {
        key: 'portfolio',
        tag: (
            <QuestionTag
                text="Portfolio management"
                iconClassName="text-teal"
                icon={RiLineChartLine}
            />
        ),
    },
    {
        key: 'budgeting',
        tag: <QuestionTag text="Budgeting" iconClassName="text-blue" icon={RiCoinLine} />,
    },
    {
        key: 'debt',
        tag: <QuestionTag text="Debt" iconClassName="text-orange " icon={RiScales3Line} />,
    },
    {
        key: 'retirement',
        tag: <QuestionTag text="Retirement" iconClassName="text-grape" icon={RiOpenArmLine} />,
    },
    {
        key: 'risk',
        tag: <QuestionTag text="Risk management" iconClassName="text-yellow" icon={RiAlertLine} />,
    },
    {
        key: 'saving',
        tag: <QuestionTag text="Saving" iconClassName="text-pink" icon={RiWallet3Line} />,
    },
    {
        key: 'estate',
        tag: <QuestionTag text="Estate planning" iconClassName="text-blue" icon={RiParentLine} />,
    },
]

type Props = {
    title: string
    subtitle: string
    category: QuestionCategory
    onClick(): void
}

export function QuestionCard({ title, subtitle, category, onClick }: Props) {
    return (
        <div
            className="flex flex-col bg-gray-800 p-4 rounded-lg sm:min-h-[250px] space-y-2 cursor-pointer hover:bg-gray-700"
            onClick={onClick}
        >
            <h5 className="text-white">{title}</h5>
            <p className="text-gray-100 grow text-base">{subtitle}</p>
            {questions.find((q) => q.key === category)?.tag}
        </div>
    )
}

type QuestionFormData = {
    question: string
}

type QuestionCardFormProps = {
    onSubmit(data: QuestionFormData): void
}

export function QuestionCardForm({ onSubmit }: QuestionCardFormProps) {
    const {
        register,
        handleSubmit,
        watch,
        formState: { isValid, isDirty },
    } = useForm<QuestionFormData>({
        mode: 'onChange',
    })

    const question = watch('question')

    return (
        <div className="flex flex-col bg-gray-800 p-4 rounded-lg sm:min-h-[250px] space-y-3">
            <h5 className="text-white">Write your own question</h5>
            <form onSubmit={handleSubmit(onSubmit)} className="flex-1 flex flex-col gap-3">
                <textarea
                    {...register('question', { required: true, maxLength: 80 })}
                    required
                    placeholder='e.g. "How can I make my savings work for me?"'
                    className="flex-1 bg-gray-500 rounded placeholder:text-gray-100 text-base resize-none outline-none ring-0 border-0 focus:outline-none focus:ring-0 focus:border-0 w-full"
                />
                <div className="flex items-center justify-between">
                    <div className="flex items-center gap-1">
                        <FractionalCircle
                            percent={((question?.length ?? 0) / 80) * 100}
                            radius={6}
                            variant={isValid || !isDirty ? 'default' : 'red'}
                        />
                        <span
                            className={classNames(
                                'text-sm font-medium',
                                isValid || !isDirty ? 'text-gray-50' : 'text-red'
                            )}
                        >
                            {question?.length ?? 0}
                        </span>
                    </div>

                    <Button variant="secondary" type="submit" disabled={!isValid}>
                        Submit
                    </Button>
                </div>
            </form>
        </div>
    )
}
