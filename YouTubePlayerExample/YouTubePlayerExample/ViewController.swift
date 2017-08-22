//
//  ViewController.swift
//  YouTubePlayerExample
//
//  Created by Akio Yasui on 2017/08/22.
//  Copyright © 2017 Akio Yasui. All rights reserved.
//

import UIKit
import YouTubePlayer

final class ViewController: UIViewController {

	@IBOutlet weak var playerView: YouTubePlayerView!
	@IBOutlet weak var playButton: UIButton!
	@IBOutlet weak var slider: UISlider!

	override func viewDidLoad() {
		super.viewDidLoad()
		playerView.delegate = self

		let displayLink = CADisplayLink(target: self, selector: #selector(step))
		displayLink.add(to: .current, forMode: .defaultRunLoopMode)
	}

	@objc func step() {
		guard playerView.state != .unstarted else {
			return
		}

		playerView.getDuration { [unowned self] duration in
			self.slider.maximumValue = Float(duration)
		}

		playerView.getCurrentTime { [unowned self] currentTime in
			self.slider.value = Float(currentTime)
		}
	}

}

extension ViewController {
	@IBAction func playButtonTouchUpInside() {
		switch playerView.state {
		case .playing:
			playerView.pause()
		case .paused, .ended:
			playerView.play()
		default:
			break
		}
	}

	@IBAction func sliderValueChanged() {
		playerView.seek(to: Double(slider.value))
	}
}

extension ViewController: YouTubePlayerViewDelegate {
	func playerViewDidFail(error: Error?, whileExecutingJavaScript script: String) {
		print("[Error] \(error?.localizedDescription ?? "unknown error") in ` \(script) `")
	}

	func playerViewAPIDidBecomeReady(_ playerView: YouTubePlayerView) {

	}

	func playerViewDidBecomeReady(_ playerView: YouTubePlayerView) {
		playerView.load(videoID: "-PV9RxRxalA")
	}

	func playerViewStateDidChange(_ playerView: YouTubePlayerView, state: YouTubePlayerView.State) {
		switch state {
		case .playing:
			playButton.setTitle("Pause", for: .normal)
		case .paused, .ended:
			playButton.setTitle("Play", for: .normal)
		default:
			playButton.setTitle("Loading", for: .normal)
		}
	}
}
