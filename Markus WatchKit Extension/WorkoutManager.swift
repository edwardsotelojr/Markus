//
//  WorkoutManager.swift
//  Markus WatchKit Extension
//
//  Created by Edward Sotelo Jr on 3/1/22.
//

import HealthKit

enum WorkoutState {

    case started, stopped

}

extension WorkoutState {

    func actionText() -> String {
        switch self {
        case .started:
            return "Stop"
        case .stopped:
            return "Start"
        }
    }
    
}

protocol WorkoutManagerDelegate: AnyObject {
    func workoutManager(_ manager: WorkoutManager, didChangeStateTo newState: WorkoutState)
    func workoutManager(_ manager: WorkoutManager, didChangeHeartRateTo newHeartRate: HeartRate)

}

class WorkoutManager: NSObject {

    // MARK: - Properties

    private let healthStore = HKHealthStore()
    fileprivate let heartRateManager = HeartRateManager()

    weak var delegate: WorkoutManagerDelegate?

    private(set) var state: WorkoutState = .stopped

    private var session: HKWorkoutSession?

    // MARK: - Initialization

    override init() {
        super.init()
        
        // Configure heart rate manager.
        heartRateManager.delegate = self
    }

    // MARK: - Public API

    func start() {
        // If we have already started the workout, then do nothing.
        if (session != nil) {
            // Another workout is running.
            print("session is not nil")
            print("session: \(session)")
            session = nil
        }
        if session?.state == .running {
            session?.stopActivity(with: Date())
        }

        if session?.state == .stopped {
            session?.end()
        }
        // Configure the workout session.
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .other
        workoutConfiguration.locationType = .indoor
        // Create workout session.
        do {
        session = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
            session!.delegate = self
            session!.startActivity(with: Date())
        } catch {
            fatalError("Unable to create Workout Session!")
        }
        // Start workout session.
        //healthStore.start(session!)

        // Update state to started and inform delegates.
        state = .started
        delegate?.workoutManager(self, didChangeStateTo: state)
    }

    func stop() {
        // If we have already stopped the workout, then do nothing.
        if (session == nil) {
            return
        }

        // Stop querying heart rate.
        heartRateManager.stop()

        // Stop the workout session.
        healthStore.end(session!)

    
        // Update state to stopped and inform delegates.
        state = .stopped
        delegate?.workoutManager(self, didChangeStateTo: state)
    }

}

// MARK: - Workout Session Delegate

extension WorkoutManager: HKWorkoutSessionDelegate {

    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("fromState:  \(fromState)")
        print("toState: \(toState)")
        switch toState {
        case .running:
            if fromState == .notStarted {
                heartRateManager.start()
            }

        default:
            
            break
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("ERROR: \(error)")
        fatalError(error.localizedDescription)
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent) {
        print("Did generate \(event)")
    }
    
}

// MARK: - Heart Rate Delegate

extension WorkoutManager: HeartRateManagerDelegate {

    func heartRate(didChangeTo newHeartRate: HeartRate) {
        delegate?.workoutManager(self, didChangeHeartRateTo: newHeartRate)
    }

}
