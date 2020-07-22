import Flutter
import UIKit
import AudioKit
import AudioKitUI


public class SwiftMicAnalyzerPlugin: NSObject, FlutterPlugin {
    
var mic: AKMicrophone!
  var tracker: AKFrequencyTracker!
   var silence: AKBooster!
    
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "mic_analyzer", binaryMessenger: registrar.messenger())
    let instance = SwiftMicAnalyzerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

    @objc func updateUI() {
        if tracker.amplitude > 0.1 {
            let trackerFrequency = Float(tracker.frequency)

            guard trackerFrequency < 7_000 else {
                // This is a bit of hack because of modern Macbooks giving super high frequencies
                return
            }
            let amplitude = Float(tracker.amplitude);
            let frequency = Float(tracker.frequency);
            
            let amplitudeR: NSNumber = NSNumber(value: amplitude)
            let frequencyR: NSNumber = NSNumber(value: frequency)
            
            
            
        }
    }
    
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    
    if (call.method == "getPlatformVersion") {
        result("iOS " + UIDevice.current.systemVersion)
        
    }else if(call.method == "init"){
        AKSettings.audioInputEnabled = true
       mic = AKMicrophone()
       tracker = AKFrequencyTracker(mic)
       silence = AKBooster(tracker, gain: 0)
        result("");
        
    }else if(call.method == "start"){
        AudioKit.output = silence
               do {
                   try AudioKit.start()
               } catch {
                   AKLog("AudioKit did not start!")
               }
        result("");
        
    }else if(call.method == "getFrequency"){
        
        let trackerFrequency = Float(tracker.frequency)
        let frequencyR: NSNumber = NSNumber(value: trackerFrequency)
        result(frequencyR);
        
        
    }else if(call.method == "getAmplitude"){
        let amplitude = Float(tracker.amplitude);
        let amplitudeR: NSNumber = NSNumber(value: amplitude)
         result(amplitudeR);
    }
    
    
  }
    
    
    
}
