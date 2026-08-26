import Foundation

/// Jieli BigData calls used by the dedicated Jieli health page.
/// No platform detection or fallback to the existing Sifli sync path is performed here.
final class JieliHealthRepository {
    static let shared = JieliHealthRepository()

    private let center: HwBluetoothCenter = HwBluetoothCenter.sharedInstance()
    private let sdk = HwBluetoothSDK.sharedInstance()

    private init() {}

    func getSleep(completion: @escaping (Result<[Any], Error>) -> Void) {
        center.getSleepBigData { list, error in
            Self.complete(list, error: error, completion: completion)
        }
    }

    func getHeartRate(completion: @escaping (Result<[Any], Error>) -> Void) {
        center.getHeartRateBigData { list, error in
            Self.complete(list, error: error, completion: completion)
        }
    }

    func getStress(completion: @escaping (Result<[Any], Error>) -> Void) {
        center.getStressBigData { list, error in
            Self.complete(list, error: error, completion: completion)
        }
    }

    func getBloodOxygen(completion: @escaping (Result<[Any], Error>) -> Void) {
        center.getBloodOxygenBigData { list, error in
            Self.complete(list, error: error, completion: completion)
        }
    }

    func getSportDetail(completion: @escaping (Result<[Any], Error>) -> Void) {
        center.getSportDetailBigData { list, error in
            Self.complete(list, error: error, completion: completion)
        }
    }

    func getWorkouts(completion: @escaping (Result<[Any], Error>) -> Void) {
        center.getWorkoutsBigData { list, error in
            Self.complete(list, error: error, completion: completion)
        }
    }

    func deleteSleep(completion: @escaping (Result<Void, Error>) -> Void) {
        sdk.deleteSleeps { success, error in
            Self.completeDelete(success, error: error, completion: completion)
        }
    }

    func deleteHeartRate(completion: @escaping (Result<Void, Error>) -> Void) {
        sdk.deleteHeartrates { success, error in
            Self.completeDelete(success, error: error, completion: completion)
        }
    }

    func deleteStress(completion: @escaping (Result<Void, Error>) -> Void) {
        center.deleteStress { success, error in
            Self.completeDelete(success, error: error, completion: completion)
        }
    }

    func deleteBloodOxygen(completion: @escaping (Result<Void, Error>) -> Void) {
        center.deleteBloodOxygen { success, error in
            Self.completeDelete(success, error: error, completion: completion)
        }
    }

    func deleteSportDetail(completion: @escaping (Result<Void, Error>) -> Void) {
        sdk.deleteActivities { success, error in
            Self.completeDelete(success, error: error, completion: completion)
        }
    }

    func deleteWorkouts(completion: @escaping (Result<Void, Error>) -> Void) {
        sdk.deleteWorkouts { success, error in
            Self.completeDelete(success, error: error, completion: completion)
        }
    }

    private static func complete(_ list: [Any]?,
                                 error: Error?,
                                 completion: @escaping (Result<[Any], Error>) -> Void) {
        DispatchQueue.main.async {
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(list ?? []))
            }
        }
    }

    private static func completeDelete(_ success: Bool,
                                       error: Error?,
                                       completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.main.async {
            if let error = error {
                completion(.failure(error))
            } else if success {
                completion(.success(()))
            } else {
                completion(.failure(SdkError(code: -1, message: L10n.tr("jieli_delete_rejected"))))
            }
        }
    }
}
