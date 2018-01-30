//
//  YouTubePlayer.swift
//  YouTubePlayer
//
//  Created by Akio Yasui on 2017/08/22.
//  Copyright © 2017 Akio Yasui. All rights reserved.
//

import UIKit
import WebKit

extension WKWebViewConfiguration {
	static var playerConfiguration: WKWebViewConfiguration {
		let configuration = WKWebViewConfiguration()
		configuration.allowsInlineMediaPlayback = true
		configuration.allowsAirPlayForMediaPlayback = true
		configuration.allowsPictureInPictureMediaPlayback = true
		configuration.mediaTypesRequiringUserActionForPlayback = []
		return configuration
	}
}

public protocol YouTubePlayerViewDelegate: class {
	func playerViewDidFail(error: Error?, whileExecutingJavaScript script: String)
	func playerViewAPIDidBecomeReady(_ playerView: YouTubePlayerView)
	func playerViewDidBecomeReady(_ playerView: YouTubePlayerView)
	func playerViewStateDidChange(_ playerView: YouTubePlayerView, state: YouTubePlayerView.State)
}

public class YouTubePlayerView: UIView {

	public enum Event: String {
		case onAPIReady = "api-ready"
		case onReady = "ready"
		case onStateChanged = "state-changed"
	}

	public enum State: Int {
		case unstarted = -1
		case ended = 0
		case playing = 1
		case paused = 2
		case buffering = 3
		case cued = 5
	}

	// MARK: Public Properties

	public weak var delegate: YouTubePlayerViewDelegate?

	public var state: State = .unstarted

	// MARK: Private Properties

	private static let baseURL = URL(string: "https://vimet.ios/")!

	fileprivate let webView: WKWebView

	// MARK: Initialization

	public override init(frame: CGRect) {
		webView = WKWebView(frame: frame, configuration: WKWebViewConfiguration.playerConfiguration)

		super.init(frame: frame)

		initialize()
	}

	public required init?(coder aDecoder: NSCoder) {
		webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration.playerConfiguration)

		super.init(coder: aDecoder)

		initialize()
	}

	private func initialize() {
		webView.frame = bounds
		webView.navigationDelegate = self
		webView.scrollView.isScrollEnabled = false
		addSubview(webView)

		let path = Bundle(for: type(of: self)).path(forResource: "player", ofType: "html")!
		let content = try! String(contentsOfFile: path)
		webView.loadHTMLString(content, baseURL: YouTubePlayerView.baseURL)

		evaluate("window.allowsInlineMediaPlayback = true")
	}

	// MARK: NSCoding

	public override func encode(with aCoder: NSCoder) {
		super.encode(with: aCoder)
	}

	// MARK: UIView

	public override func layoutSubviews() {
		super.layoutSubviews()
		webView.frame = bounds
	}

}

// JavaScript Execution
extension YouTubePlayerView {
	fileprivate func evaluate(_ script: String, completion: @escaping () -> Void = {}) {
		webView.evaluateJavaScript(script) { [weak delegate] result, error in
			guard error == nil else {
				delegate?.playerViewDidFail(error: error, whileExecutingJavaScript: script)
				return
			}
			completion()
		}
	}

	fileprivate func evaluate<T>(_ script: String, completion: @escaping (T) -> Void = { _ in }) {
		webView.evaluateJavaScript(script) { [weak delegate] result, error in
			guard error == nil, let result = result as? T else {
				delegate?.playerViewDidFail(error: error, whileExecutingJavaScript: script)
				return
			}
			completion(result)
		}
	}
}

// MARK: Actions
extension YouTubePlayerView {
	public func load(videoID: String) {
		evaluate("!window.player.loadVideoById('\(videoID)')")
	}

	public func play() {
		evaluate("!window.player.playVideo()")
	}

	public func pause() {
		evaluate("!window.player.pauseVideo()")
	}

	public func stop() {
		evaluate("!window.player.stopVideo()")
	}

	public func mute() {
		evaluate("!window.player.mute()")
	}

	public func unMute() {
		evaluate("!window.player.unMute()")
	}

	public func seek(to seconds: Double) {
		evaluate("!window.player.seekTo(\(seconds), true)")
	}

	public func getDuration(completion: @escaping (_ duration: Double) -> ()) {
		evaluate("window.player.getDuration()", completion: completion)
	}

	public func getCurrentTime(completion: @escaping (_ currentTime: Double) -> ()) {
		evaluate("window.player.getCurrentTime()", completion: completion)
	}

	public func isMuted(completion: @escaping (_ isMuted: Bool) -> ()) {
		evaluate("window.player.isMuted()", completion: completion)
	}
}

extension YouTubePlayerView: WKNavigationDelegate {
	public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
		let policy: WKNavigationActionPolicy
		defer { decisionHandler(policy) }

		guard
			let url = navigationAction.request.url,
			case let ("sh-aky-youtube-player"?, path) = (url.scheme, url.path) else
		{
			policy = .allow
			return
		}

		policy = .cancel

		let name = String(path[path.index(after: path.startIndex)...])
		guard let delegate = delegate, let event = Event(rawValue: name) else {
			return
		}

		var data = [String: String?]()
		let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
		for item in components?.queryItems ?? [] {
			data[item.name] = item.value
		}

		switch event {
		case .onAPIReady:
			delegate.playerViewAPIDidBecomeReady(self)
		case .onReady:
			delegate.playerViewDidBecomeReady(self)
		case .onStateChanged:
			let state = data["state"]?.flatMap { Int($0, radix: 10) }.flatMap { State(rawValue: $0) } ?? .unstarted
			self.state = state
			delegate.playerViewStateDidChange(self, state: state)
		}
	}
}
