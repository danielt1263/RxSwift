//
//  Observable+OverlappingBufferTests.swift
//  AllTests-iOS
//
//  Created by Daniel Tartaglia on 4/29/24.
//  Copyright © 2024 Krunoslav Zaher. All rights reserved.
//

import XCTest
import RxSwift
import RxTest

final class ObservableOverlappingBufferTests: RxTest {
	func testBufferWithCountAndSkipEqual() {
		let scheduler = TestScheduler(initialClock: 0)

		let xs = scheduler.createHotObservable([
			.next(201, 1),
			.next(203, 2),
			.next(205, 3),
			.next(207, 4),
			.next(209, 5),
			.next(211, 6),
			.completed(213)
		])

		let res = scheduler.start {
			xs.buffer(count: 2, skip: 2)
		}

		XCTAssertEqual(res.events, [
			.next(203, [1, 2]),
			.next(207, [3, 4]),
			.next(211, [5, 6]),
			.next(213, []),
			.completed(213)
		])
	}

	func testBufferWithCountLessThanSkip() {
		let scheduler = TestScheduler(initialClock: 0)

		let xs = scheduler.createHotObservable([
			.next(201, 1),
			.next(203, 2),
			.next(205, 3),
			.next(207, 4),
			.next(209, 5),
			.next(211, 6),
			.completed(213)
		])

		let res = scheduler.start {
			xs.buffer(count: 2, skip: 3)
		}

		XCTAssertEqual(res.events, [
			.next(203, [1, 2]),
			.next(209, [4, 5]),
			.next(213, []),
			.completed(213)
		])
	}

	func testBufferWithSkipLessThanCount() {
		let scheduler = TestScheduler(initialClock: 0)

		let xs = scheduler.createHotObservable([
			.next(201, 1),
			.next(203, 2),
			.next(205, 3),
			.next(207, 4),
			.next(209, 5),
			.next(211, 6),
			.completed(213)
		])

		let res = scheduler.start {
			xs.buffer(count: 3, skip: 2)
		}

		XCTAssertEqual(res.events, [
			.next(205, [1, 2, 3]),
			.next(209, [3, 4, 5]),
			.next(213, [5, 6]),
			.completed(213)
		])
	}

	func testBufferTimeSpanEqualToTimeShift() {
		let scheduler = TestScheduler(initialClock: 0)

		let xs = scheduler.createHotObservable([
			.next(201, 1),
			.next(203, 2),
			.next(205, 3),
			.next(207, 4),
			.next(209, 5),
			.next(211, 6),
			.completed(213)
		])

		let res = scheduler.start {
			xs.buffer(timeSpan: .seconds(4), timeShift: .seconds(4), scheduler: scheduler)
		}

		XCTAssertEqual(res.events, [
			.next(204, [1, 2]),
			.next(208, [3, 4]),
			.next(212, [5, 6]),
			.next(213, []),
			.completed(213)
		])
	}

	func testBufferTimeSpanLessThanTimeShift() {
		let scheduler = TestScheduler(initialClock: 0)

		let xs = scheduler.createHotObservable([
			.next(201, 1),
			.next(203, 2),
			.next(205, 3),
			.next(207, 4),
			.next(209, 5),
			.next(211, 6),
			.completed(213)
		])

		let res = scheduler.start {
			xs.buffer(timeSpan: .seconds(4), timeShift: .seconds(6), scheduler: scheduler)
		}

		XCTAssertEqual(res.events, [
			.next(204, [1, 2]),
			.next(210, [4, 5]),
			.next(213, []),
			.completed(213)
		])
	}

	func testBufferTimeShiftLessThanTimeSpan() {
		let scheduler = TestScheduler(initialClock: 0)

		let xs = scheduler.createHotObservable([
			.next(201, 1),
			.next(203, 2),
			.next(205, 3),
			.next(207, 4),
			.next(209, 5),
			.next(211, 6),
			.completed(213)
		])

		let res = scheduler.start {
			xs.buffer(timeSpan: .seconds(6), timeShift: .seconds(4), scheduler: scheduler)
		}

		XCTAssertEqual(res.events, [
			.next(206, [1, 2, 3]),
			.next(210, [3, 4, 5]),
			.next(213, [5, 6]),
			.completed(213)
		])
	}
}
