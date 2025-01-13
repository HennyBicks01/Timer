import Intents

class IntentHandler: INExtension {
    override func handler(for intent: INIntent) -> Any {
        if intent is INSetTimerIntent {
            return TimerIntentHandler()
        }
        return self
    }
}

class TimerIntentHandler: NSObject, INSetTimerIntentHandling {
    func handle(intent: INSetTimerIntent, completion: @escaping (INSetTimerIntentResponse) -> Void) {
        guard let duration = intent.duration, duration > 0 else {
            completion(INSetTimerIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        completion(INSetTimerIntentResponse(code: .handleInApp, userActivity: nil))
    }
    
    func resolveTimer(for intent: INSetTimerIntent, with completion: @escaping (INTimerResolutionResult) -> Void) {
        if let duration = intent.duration, duration > 0 {
            completion(.success(with: duration))
        } else {
            completion(.unsupported())
        }
    }
}
