import { RiSearch2Line } from 'react-icons/ri'

type Props = { onChange(query: string): void }
export default function UserSearch({ onChange }: Props) {
    return (
        <div className="mt-6 flex space-x-4">
            <div className="min-w-0 flex-1">
                <label htmlFor="search" className="sr-only">
                    Search
                </label>
                <div className="relative rounded-md shadow-sm">
                    <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
                        <RiSearch2Line className="text-gray-200" aria-hidden="true" />
                    </div>
                    <input
                        onChange={(e) => onChange(e.target.value)}
                        type="search"
                        className="block w-full rounded-md bg-transparent border-gray-300 pl-10 focus:border-gray-500 focus:ring-gray-500 sm:text-sm placeholder:text-gray-200"
                        placeholder="Search"
                    />
                </div>
            </div>
        </div>
    )
}
