export interface IETL<TInput, TExtracted = any, TTransformed = TExtracted> {
    extract(input: TInput): Promise<TExtracted>
    transform(input: TInput, extracted: TExtracted): Promise<TTransformed>
    load(input: TInput, transformed: TTransformed): Promise<void>
}

export async function etl<TInput, TExtracted, TTransformed>(
    service: IETL<TInput, TExtracted, TTransformed>,
    input: TInput
): Promise<void> {
    const extracted = await service.extract(input)
    const transformed = await service.transform(input, extracted)
    await service.load(input, transformed)
}
