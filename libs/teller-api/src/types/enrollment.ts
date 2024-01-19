export type Enrollment = {
    accessToken: string
    user: {
        id: string
    }
    enrollment: {
        id: string
        institution: {
            name: string
        }
    }
    signatures?: string[]
}
