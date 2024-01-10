import range from 'lodash/range'

type MonteCarloOptions = {
    n: number
}

export function monteCarlo<T>(
    fn: (i: number) => T,
    { n = 1_000 }: Partial<MonteCarloOptions> = {}
) {
    return range(n).map(fn)
}
