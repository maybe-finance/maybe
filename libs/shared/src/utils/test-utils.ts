export function axiosSuccess<T>(data: T) {
    return {
        status: 200,
        statusText: '200',
        headers: {},
        config: {},
        data,
    }
}

export function axios400Error<T>(data: T) {
    return {
        config: {},
        response: {
            status: 400,
            statusText: '400',
            headers: {},
            config: {},
            data,
        },
        isAxiosError: true,
    }
}
