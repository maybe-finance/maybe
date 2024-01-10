import { Button } from '@maybe-finance/design-system'
import { RiCloseFill } from 'react-icons/ri'

type Props = {
    name: string
    onClear(): void
}

export function UploadFile({ name, onClear }: Props) {
    return (
        <div className="flex items-center gap-3 text-base bg-gray-700 justify-between px-3 py-2 rounded-xl">
            <span className="truncate">{name}</span>

            <Button variant="icon" type="button">
                <RiCloseFill size={24} onClick={onClear} />
            </Button>
        </div>
    )
}
