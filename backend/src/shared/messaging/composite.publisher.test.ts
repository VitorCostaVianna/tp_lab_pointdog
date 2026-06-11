import { CompositePublisher } from './composite.publisher'
import { IEventPublisher } from './event-publisher.interface'

describe('CompositePublisher', () => {
  it('should call publish on all publishers', async () => {
    const publishA = jest.fn().mockResolvedValue(undefined)
    const publishB = jest.fn().mockResolvedValue(undefined)
    const a: IEventPublisher = { publish: publishA }
    const b: IEventPublisher = { publish: publishB }

    const composite = new CompositePublisher([a, b])
    await composite.publish('test.event', { data: 1 })

    expect(publishA).toHaveBeenCalledWith('test.event', { data: 1 })
    expect(publishB).toHaveBeenCalledWith('test.event', { data: 1 })
  })

  it('should reject if any publisher rejects', async () => {
    const ok: IEventPublisher = { publish: jest.fn().mockResolvedValue(undefined) }
    const fail: IEventPublisher = { publish: jest.fn().mockRejectedValue(new Error('fail')) }

    const composite = new CompositePublisher([ok, fail])
    await expect(composite.publish('x', {})).rejects.toThrow('fail')
  })
})
