// A simplified version of: https://jsonapi.org/examples/#error-objects-multiple-errors
export interface ErrorResponse {
    errors: Array<{ status: string; title: string; detail?: string }>
}

export interface SuccessResponse {
    data: {
        json: any // eslint-disable-line
        meta?: any // eslint-disable-line
    }
    [metadata: string]: any // eslint-disable-line
}

// Can be used in Axios typings in components
// eslint-disable-next-line
export interface ApiResponse<T = any> {
    data?: T
    errors?: ErrorResponse['errors']
}

// eslint-disable-next-line
export type BaseResponse = SuccessResponse | ErrorResponse
