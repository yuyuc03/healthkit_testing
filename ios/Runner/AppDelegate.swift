import Flutter
import UIKit
import flutter_local_notifications
import HealthKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }

    GeneratedPluginRegistrant.register(with: self)

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let healthChannel = FlutterMethodChannel(name: "com.example.healthkitIntegrationTesting/background",
                                             binaryMessenger: controller.binaryMessenger)
    
    healthChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "setupHealthKitObservers" {
        self?.setupHealthKitObservers(result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func setupHealthKitObservers(result: @escaping FlutterResult) {
    if HKHealthStore.isHealthDataAvailable() {
      let healthStore = HKHealthStore()
      
      // Define the types you want to observe
      var typesToObserve: Set<HKObjectType> = []
      
      // Add blood pressure types
      if let systolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic) {
        typesToObserve.insert(systolicType)
      }
      
      if let diastolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic) {
        typesToObserve.insert(diastolicType)
      }
      
      // Add blood glucose
      if let bloodGlucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose) {
        typesToObserve.insert(bloodGlucoseType)
      }
      
      // Add dietary cholesterol
      if let dietaryCholesterolType = HKObjectType.quantityType(forIdentifier: .dietaryCholesterol) {
        typesToObserve.insert(dietaryCholesterolType)
      }
      
      // Add blood oxygen
      if let bloodOxygenType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) {
        typesToObserve.insert(bloodOxygenType)
      }
      
      // Add respiratory rate
      if let respiratoryRateType = HKObjectType.quantityType(forIdentifier: .respiratoryRate) {
        typesToObserve.insert(respiratoryRateType)
      }
      
      // Add heart rate
      if let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) {
        typesToObserve.insert(heartRateType)
      }
      
      // Add active energy burned
      if let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
        typesToObserve.insert(activeEnergyType)
      }
      
      // Add exercise time (appleExerciseTime)
      if let exerciseTimeType = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) {
        typesToObserve.insert(exerciseTimeType)
      }
      
      // Add steps
      if let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) {
        typesToObserve.insert(stepsType)
      }
      
      // Request authorization
      healthStore.requestAuthorization(toShare: nil, read: typesToObserve) { (success, error) in
        if success {
          var setupSuccess = true
          let group = DispatchGroup()
          
          for type in typesToObserve {
            group.enter()
            
            // Create observer query
            let query = HKObserverQuery(sampleType: type as! HKSampleType, predicate: nil) { [weak self] (query, completionHandler, error) in
              // Handle new data
              if let error = error {
                print("Observer query error: \(error.localizedDescription)")
              } else {
                // Get the controller for method channel communication
                DispatchQueue.main.async {
                  if let controller = self?.window?.rootViewController as? FlutterViewController {
                    let methodChannel = FlutterMethodChannel(
                      name: "com.example.healthkitIntegrationTesting/background",
                      binaryMessenger: controller.binaryMessenger
                    )
                    methodChannel.invokeMethod("healthDataUpdated", arguments: nil)
                  }
                }
              }
              
              // Complete the background task
              completionHandler()
            }
            
            // Execute the query
            healthStore.execute(query)
            
            // Enable background delivery
            healthStore.enableBackgroundDelivery(for: type as! HKSampleType, frequency: .immediate, withCompletion: { (success, error) in
              defer { group.leave() }
              
              if let error = error {
                print("Failed to enable background delivery for \(type): \(error.localizedDescription)")
                setupSuccess = false
              } else {
                print("Successfully enabled background delivery for \(type)")
              }
            })
          }
          
          group.notify(queue: .main) {
            result(setupSuccess)
          }
        } else if let error = error {
          print("Authorization failed: \(error.localizedDescription)")
          result(false)
        } else {
          result(false)
        }
      }
    } else {
      result(false)
    }
  }
}
