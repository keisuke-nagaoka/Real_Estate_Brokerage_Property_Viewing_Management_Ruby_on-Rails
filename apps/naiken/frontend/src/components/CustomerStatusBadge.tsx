import { customerStatusLabels } from '../lib/labels'
import type { CustomerStatus } from '../types'

export function CustomerStatusBadge({ status }: { status: CustomerStatus }) {
  return <span className={`badge badge-cs-${status}`}>{customerStatusLabels[status]}</span>
}
