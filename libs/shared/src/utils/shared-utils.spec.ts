import _ from 'lodash'
import { paginate, paginateIt, chunkIt, withRetry } from './shared-utils'

describe('paginate', () => {
    it.each`
        pageSize | dataSize | fetchCalls
        ${10}    | ${0}     | ${1}
        ${10}    | ${1}     | ${1}
        ${10}    | ${10}    | ${2}
        ${10}    | ${11}    | ${2}
        ${10}    | ${20}    | ${3}
    `(
        `paginates correctly: (pageSize: $pageSize, dataSize: $dataSize)`,
        async ({ pageSize, dataSize, fetchCalls }) => {
            const mockFetchData = jest.fn((offset, count) =>
                Promise.resolve(_.slice(_.range(dataSize), offset, offset + count))
            )

            const result = await paginate({
                pageSize,
                fetchData: mockFetchData,
            })

            expect(result).toHaveLength(dataSize)
            expect(result).toEqual(_.range(dataSize))

            expect(mockFetchData).toHaveBeenCalledTimes(fetchCalls)
            _.range(fetchCalls).map((i) => {
                expect(mockFetchData).toHaveBeenNthCalledWith(i + 1, i * pageSize, pageSize)
            })
        }
    )
})

describe('paginateIt', () => {
    it.each`
        pageSize | dataSize | fetchCalls
        ${10}    | ${0}     | ${1}
        ${10}    | ${1}     | ${1}
        ${10}    | ${10}    | ${2}
        ${10}    | ${11}    | ${2}
        ${10}    | ${20}    | ${3}
    `(
        `paginates correctly: (pageSize: $pageSize, dataSize: $dataSize)`,
        async ({ pageSize, dataSize, fetchCalls }) => {
            const mockFetchData = jest.fn((offset, count) =>
                Promise.resolve(_.slice(_.range(dataSize), offset, offset + count))
            )

            const it = paginateIt({
                pageSize,
                fetchData: mockFetchData,
            })

            const result = []
            for await (const page of it) {
                result.push(...page)
            }

            expect(result).toHaveLength(dataSize)
            expect(result).toEqual(_.range(dataSize))

            expect(mockFetchData).toHaveBeenCalledTimes(fetchCalls)
            _.range(fetchCalls).map((i) => {
                expect(mockFetchData).toHaveBeenNthCalledWith(i + 1, i * pageSize, pageSize)
            })
        }
    )
})

describe('chunkIt', () => {
    it('lazily chunks iterable', async () => {
        const data = ['a', 'b', 'c']

        const yieldTracker = jest.fn(() => {
            /* noop */
        })

        const iterable: AsyncIterable<string> = {
            async *[Symbol.asyncIterator]() {
                for (const x of data) {
                    yieldTracker()
                    yield x
                }
            },
        }

        const it = chunkIt(iterable, 2)

        const chunk1 = await it.next()
        expect(chunk1.value).toHaveLength(2)
        expect(chunk1.value).toEqual(['a', 'b'])
        expect(yieldTracker).toHaveBeenCalledTimes(2)

        const chunk2 = await it.next()
        expect(chunk2.value).toHaveLength(1)
        expect(chunk2.value).toEqual(['c'])
        expect(yieldTracker).toHaveBeenCalledTimes(3)
    })
})

describe('withRetry', () => {
    it.each`
        failAttempts | maxRetries
        ${0}         | ${5}
        ${1}         | ${5}
        ${2}         | ${5}
        ${5}         | ${5}
    `(
        `retries correctly: (failAttempts: $failAttempts, maxRetries: $maxRetries)`,
        async ({ failAttempts, maxRetries }) => {
            const mock = jest.fn((attempt) => {
                if (attempt < failAttempts) throw new Error(`keep trying!`)
                return 'done'
            })

            await withRetry(mock, { maxRetries })

            expect(mock).toHaveBeenCalledTimes(failAttempts + 1)
            _.range(failAttempts + 1).map((i) => {
                expect(mock).toHaveBeenNthCalledWith(i + 1, i)
            })
        }
    )

    it(`throws last error`, async () => {
        const maxRetries = 5

        const mock = jest.fn((attempt) => {
            throw new Error(`keep trying! attempt: ${attempt}`)
        })

        expect(withRetry(mock, { maxRetries })).rejects.toThrow()
        expect(mock).toHaveBeenCalledTimes(maxRetries + 1)
    })

    it(`obeys onError poison pill`, async () => {
        const maxRetries = 5
        const exitAfterAttempts = 1

        const mock = jest.fn((attempt) => {
            throw new Error(`keep trying! attempt: ${attempt}`)
        })

        const mockOnError = jest.fn((_err, attempt) => attempt < exitAfterAttempts)

        expect(withRetry(mock, { maxRetries, onError: mockOnError })).rejects.toThrow()
        expect(mock).toHaveBeenCalledTimes(exitAfterAttempts + 1)
        expect(mockOnError).toHaveBeenCalledTimes(exitAfterAttempts + 1)
    })
})
