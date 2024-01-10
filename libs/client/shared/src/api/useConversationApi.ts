import type { Conversation, Message } from '@prisma/client'
import type { AxiosInstance } from 'axios'
import type { SharedType } from '@maybe-finance/shared'
import type { UseMutationOptions, UseQueryOptions } from '@tanstack/react-query'
import { useMemo } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAxiosWithAuth } from '..'
import toast from 'react-hot-toast'

type CreateMessage = {
    type: Message['type']
    body: string
    attachment: File | null
}

const ConversationApi = (
    axios: AxiosInstance,
    axiosAuthOnly: AxiosInstance,
    defaultBaseUrl: string
) => ({
    async getConversations() {
        const { data } = await axios.get<SharedType.ConversationWithMessageSummary[]>(
            '/conversations'
        )
        return data
    },

    async get(id: Conversation['id']) {
        const { data } = await axios.get<SharedType.ConversationWithDetail>(`/conversations/${id}`)
        return data
    },

    async create(input: Record<string, any>) {
        const { data } = await axios.post<Conversation>('/conversations', input)
        return data
    },

    async createMessage(id: Conversation['id'], input: CreateMessage) {
        const form = new FormData()

        form.append('type', input.type)
        form.append('body', input.body)

        if (input.attachment) {
            form.append('attachment', input.attachment)
        }

        const { data } = await axiosAuthOnly.post<Message>(`/conversations/${id}/messages`, form, {
            headers: { 'Content-Type': 'multipart/form-data' },
            baseURL: defaultBaseUrl,
        })

        return data
    },

    async update(id: Conversation['id'], input: Record<string, any>) {
        const { data } = await axios.patch<Conversation>(`/conversations/${id}`, input)
        return data
    },

    async delete(id: Conversation['id']) {
        const { data } = await axios.delete<Conversation>(`/conversations/${id}`)
        return data
    },
})

const staleTimes = {
    conversations: 30_000,
}

export function useConversationApi() {
    const queryClient = useQueryClient()
    const { axios, createInstance, defaultBaseUrl, getToken } = useAxiosWithAuth()
    const api = useMemo(
        () => ConversationApi(axios, createInstance({ getToken }), defaultBaseUrl),
        [axios, createInstance, getToken, defaultBaseUrl]
    )

    const useConversations = (
        options?: Omit<
            UseQueryOptions<
                SharedType.ConversationWithMessageSummary[],
                unknown,
                SharedType.ConversationWithMessageSummary[],
                string[]
            >,
            'queryKey' | 'queryFn' | 'staleTime'
        >
    ) =>
        useQuery(['conversations'], api.getConversations, {
            staleTime: staleTimes.conversations,
            ...options,
        })

    const useConversation = (
        id: Conversation['id'],
        options?: Omit<
            UseQueryOptions<
                SharedType.ConversationWithDetail,
                unknown,
                SharedType.ConversationWithDetail,
                any[]
            >,
            'queryKey' | 'queryFn' | 'staleTime'
        >
    ) => {
        return useQuery(['conversations', id], () => api.get(id), {
            staleTime: staleTimes.conversations,
            ...options,
        })
    }

    const useCreateConversation = (
        options?: UseMutationOptions<Conversation, unknown, Record<string, any>>
    ) =>
        useMutation(api.create, {
            onSuccess: () => {
                toast.success('Conversation successfully added!')
            },
            onError: () => {
                toast.error('Error adding conversation')
            },
            onSettled: () => {
                queryClient.invalidateQueries(['conversations'])
                queryClient.invalidateQueries(['users', 'onboarding'])
            },
            ...options,
        })

    const useCreateMessage = (
        options?: UseMutationOptions<
            Message,
            unknown,
            { id: Conversation['id']; data: CreateMessage }
        >
    ) =>
        useMutation(
            ({ id, data }: { id: Conversation['id']; data: CreateMessage }) =>
                api.createMessage(id, data),
            {
                onSuccess: () => {
                    toast.success('Message sent!')
                },
                onError: () => {
                    toast.error('Error sending message')
                },
                onSettled: () => {
                    queryClient.invalidateQueries(['conversations'])
                },
                ...options,
            }
        )

    const useUpdateConversation = () =>
        useMutation(
            ({ id, data }: { id: Conversation['id']; data: Record<string, any> }) =>
                api.update(id, data),
            {
                onSuccess: () => {
                    toast.success('Conversation successfully updated!')
                },
                onError: () => {
                    toast.error('Error updating conversation')
                },
                onSettled: () => {
                    queryClient.invalidateQueries(['conversations'])
                },
            }
        )

    const useDeleteConversation = () =>
        useMutation(api.delete, {
            onSuccess: () => {
                toast.success(`Conversation deleted!`)
            },
            onError: () => {
                toast.error('Failed to delete conversation')
            },
            onSettled: () => {
                queryClient.invalidateQueries(['conversations'])
            },
        })

    const useSandbox = () =>
        useMutation(
            async (input: Record<string, any>) => {
                const { data } = await axios.post<{
                    action: string
                    success: boolean
                }>(`/conversations/sandbox`, input)
                return data
            },
            {
                onSuccess: (data) => {
                    toast.success(`${data.action} success`)
                },
                onSettled: () => {
                    queryClient.invalidateQueries(['conversations'])
                },
                onError: (err) => {
                    toast.error(JSON.stringify(err))
                },
            }
        )

    return {
        useConversations,
        useConversation,
        useCreateConversation,
        useUpdateConversation,
        useCreateMessage,
        useSandbox,
    }
}
