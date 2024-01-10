import * as csv from '@fast-csv/parse'

export async function parseCsv<Keys extends string>(path: string): Promise<Record<Keys, string>[]> {
    return new Promise((resolve) => {
        const stream = csv.parseFile(path, { headers: true })
        const data: any = []
        stream.on('data', (row) => data.push(row))
        stream.on('end', () => resolve(data))
    })
}
