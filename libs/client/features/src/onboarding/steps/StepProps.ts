export type StepProps = {
    title: string
    onNext(): Promise<void>
    onPrev(): Promise<void>
}
