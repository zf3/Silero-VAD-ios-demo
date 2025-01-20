import UIKit

class MicVadViewController: UIViewController {
    @IBOutlet weak var voiceIndicator: UIView!
    @IBOutlet weak var indicatorCircle: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make the indicator circle round
        indicatorCircle.layer.cornerRadius = indicatorCircle.frame.width / 2
        indicatorCircle.clipsToBounds = true
    }
}
