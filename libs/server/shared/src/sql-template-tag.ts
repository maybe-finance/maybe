/**
 * This is a copy of the sql-template-tag package, I wasn't able to use the npm package due to errors with nx/webpack and ESM modules
 * https://github.com/blakeembrey/sql-template-tag
 */
export type Value =
    | string
    | number
    | boolean
    | Date
    | null
    | undefined
    | Value[]
    | { [key: string | number]: Value }

export type RawValue = Value | Sql

/**
 * A SQL instance can be nested within each other to build SQL strings.
 */
export class Sql {
    values: Value[]
    strings: string[]

    constructor(rawStrings: ReadonlyArray<string>, rawValues: ReadonlyArray<RawValue>) {
        let valuesLength = rawValues.length
        let stringsLength = rawStrings.length

        if (stringsLength === 0) {
            throw new TypeError('Expected at least 1 string')
        }

        if (stringsLength - 1 !== valuesLength) {
            throw new TypeError(
                `Expected ${stringsLength} strings to have ${stringsLength - 1} values`
            )
        }

        for (const child of rawValues) {
            if (child instanceof Sql) {
                valuesLength += child.values.length - 1
                stringsLength += child.strings.length - 2
            }
        }

        this.values = new Array(valuesLength)
        this.strings = new Array(stringsLength)

        this.strings[0] = rawStrings[0]

        // Iterate over raw values, strings, and children. The value is always
        // positioned between two strings, e.g. `index + 1`.
        let index = 1
        let position = 0
        while (index < rawStrings.length) {
            const child = rawValues[index - 1]
            const rawString = rawStrings[index++]

            // Check for nested `sql` queries.
            if (child instanceof Sql) {
                // Append child prefix text to current string.
                this.strings[position] += child.strings[0]

                let childIndex = 0
                while (childIndex < child.values.length) {
                    this.values[position++] = child.values[childIndex++]
                    this.strings[position] = child.strings[childIndex]
                }

                // Append raw string to current string.
                this.strings[position] += rawString
            } else {
                this.values[position++] = child
                this.strings[position] = rawString
            }
        }
    }

    get text() {
        return this.strings.reduce((text, part, index) => `${text}$${index}${part}`)
    }

    get sql() {
        return this.strings.join('?')
    }

    inspect() {
        return {
            text: this.text,
            sql: this.sql,
            values: this.values,
        }
    }
}

/**
 * Create a SQL query for a list of values.
 */
export function join(values: RawValue[], separator = ',') {
    if (values.length === 0) {
        throw new TypeError(
            'Expected `join([])` to be called with an array of multiple elements, but got an empty array'
        )
    }

    return new Sql(['', ...Array(values.length - 1).fill(separator), ''], values)
}

/**
 * Create raw SQL statement.
 */
export function raw(value: string) {
    return new Sql([value], [])
}

/**
 * Placeholder value for "no text".
 */
export const empty = raw('')

/**
 * Create a SQL object from a template string.
 */
export default function sql(strings: ReadonlyArray<string>, ...values: RawValue[]) {
    return new Sql(strings, values)
}
