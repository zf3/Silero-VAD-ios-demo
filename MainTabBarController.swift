import UIKit
import Silero_VAD_for_iOS

class MainTabBarController: UITabBarController {
    let vad = VoiceActivityDetector()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Inject VAD instance into child view controllers
        if let viewControllers = self.viewControllers {
            for case let vc as VADContainer in viewControllers {
                vc.vad = vad
            }
        }
    }
}

protocol VADContainer: AnyObject {
    var vad: VoiceActivityDetector? { get set }
}
