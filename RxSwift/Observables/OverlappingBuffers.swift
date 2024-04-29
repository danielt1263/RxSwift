//
//  OverlappingBuffers.swift
//  RxSwift
//
//  Created by Daniel Tartaglia on 4/29/24.
//  Copyright © 2024 Krunoslav Zaher. All rights reserved.
//

import Foundation

extension ObservableType {
	/**
	 Projects elements from an observable sequence into a buffer that's sent out when its full and then every `skip`
	 elements.

	 - seealso: [overlapping buffers in Introduction to Rx](https://introtorx.com/chapters/partitioning#OverlappingBuffers)

	 - parameter count: Size of the array of elements that will be produced in each event.
	 - parameter skip: Number of elements that must emit from the source before the buffer emits.
	 - returns: An observable sequence of buffers.
	 */
	public func buffer(count: Int, skip: Int) -> Observable<[Element]> {
		precondition(
			skip > 0,
			"The `skip` parameter cannot be less than or equal to zero. If you want to use a value of zero (i.e. each buffer contains all values), then consider using the `scan` method instead with an Array<T> as the accumulator."
		)

		return materialize()
			.scan(into: (buf: [Element](), step: count, trigger: false)) { prev, event in
				switch event {
				case let .next(value):
					let newStep = prev.step - 1
					prev.buf.append(value)
					if prev.buf.count > count {
						prev.buf.removeFirst()
					}
					prev.step = newStep == 0 ? skip : newStep
					prev.trigger = newStep == 0
				case .completed:
					prev.buf = Array(prev.buf.suffix(count - prev.step))
					prev.step = 0
					prev.trigger = true
				case let .error(error):
					throw error
				}
			}
			.filter { $0.trigger }
			.map { $0.buf }
	}
}

extension ObservableType {
	/**
	 Projects elements from an observable sequence into a buffer that's sent out after `timeSpan` and then every
	 `timeShift` seconds.

	 - seealso: [overlapping buffers in Introduction to Rx](https://introtorx.com/chapters/partitioning#OverlappingBuffers)

	 - parameter timeSpan: The amount of time the operator will spend gathering events.
	 - parameter timeShift: The amount of time that must pass before the buffer emits.
	 - parameter scheduler: Scheduler to run timers on.
	 - returns: An observable sequence of buffers.
	 */
	public func buffer(timeSpan: RxTimeInterval, timeShift: RxTimeInterval,
				scheduler: SchedulerType) -> Observable<[Element]>
	{
		precondition(
			timeShift.asTimeInterval > 0,
			"The `timeShift` parameter cannot be less than or equal to zero. If you want to use a value of zero (i.e. each buffer contains all values), then consider using the `scan` method instead with an Array<T> as the accumulator."
		)
		return Observable.create { observer in
			var buf: [Date: Element] = [:]
			var lastEmit: Date?
			let lock = NSRecursiveLock()
			let bufferDispoable = self.subscribe { event in
				lock.lock(); defer { lock.unlock() }
				let now = scheduler.now
				switch event {
				case let .next(element):
					buf[now] = element
				case .completed:
					let span = now.timeIntervalSince(lastEmit ?? .distantPast)
						+ timeSpan.asTimeInterval
						- timeShift.asTimeInterval
					let buffer = buf
						.filter { $0.key > now.addingTimeInterval(-span) }
						.sorted(by: { $0.key <= $1.key })
						.map { $0.value }
					observer.onNext(buffer)
					observer.onCompleted()
				case let .error(error):
					observer.onError(error)
				}
			}
			let schedulerDisposable = scheduler.schedulePeriodic(
				(),
				startAfter: timeSpan,
				period: timeShift,
				action: { _ in
					lock.lock(); defer { lock.unlock() }
					let now = scheduler.now
					buf = buf.filter { $0.key > now.addingTimeInterval(-timeSpan.asTimeInterval) }
					observer.onNext(buf.sorted(by: { $0.key <= $1.key }).map { $0.value })
					lastEmit = now
				}
			)
			return Disposables.create([schedulerDisposable, bufferDispoable])
		}
	}
}
