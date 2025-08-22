//
//  CodeDiffViewController.swift
//  
//
//  Created by Claude Code on 8/22/25.
//

import Foundation
import WebKit

#if os(OSX)
import AppKit
#elseif os(iOS)
import UIKit
#endif

public class CodeDiffViewController: NSObject {
    
    var parent: CodeDiffView
    var webView: WKWebView?
    
    init(_ parent: CodeDiffView) {
        self.parent = parent
    }
    
    func setWebView(_ webView: WKWebView) {
        self.webView = webView
    }
}

// MARK: - WKNavigationDelegate

extension CodeDiffViewController: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        parent.onLoadSuccess?()
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        parent.onLoadFail?(error)
    }
}

// MARK: - WKScriptMessageHandler

extension CodeDiffViewController: WKScriptMessageHandler {
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        switch message.name {
        case CodeDiffViewRPC.isReady:
            // Diff view is ready
            break
        default:
            break
        }
    }
}

// MARK: - JavaScript Interface

extension CodeDiffViewController {
    
    func setThemeName(_ theme: String) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("SetDiffTheme('\(theme)')") { _, _ in }
    }
    
    func setMimeType(_ mimeType: String) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("SetDiffMimeType('\(mimeType)')") { _, _ in }
    }
    
    func setOriginalCode(_ code: String) {
        guard let webView = webView else { return }
        let escapedCode = code.replacingOccurrences(of: "\\", with: "\\\\")
                             .replacingOccurrences(of: "'", with: "\\'")
                             .replacingOccurrences(of: "\n", with: "\\n")
                             .replacingOccurrences(of: "\r", with: "\\r")
        webView.evaluateJavaScript("SetOriginalCode('\(escapedCode)')") { _, _ in }
    }
    
    func setModifiedCode(_ code: String) {
        guard let webView = webView else { return }
        let escapedCode = code.replacingOccurrences(of: "\\", with: "\\\\")
                             .replacingOccurrences(of: "'", with: "\\'")
                             .replacingOccurrences(of: "\n", with: "\\n")
                             .replacingOccurrences(of: "\r", with: "\\r")
        webView.evaluateJavaScript("SetModifiedCode('\(escapedCode)')") { _, _ in }
    }
    
    func setFontSize(_ fontSize: Int) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("SetDiffFontSize(\(fontSize))") { _, _ in }
    }
    
    func setShowLineNumbers(_ show: Bool) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("SetDiffLineNumbers(\(show))") { _, _ in }
    }
    
    func setCollapseIdentical(_ collapse: Bool) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("SetCollapseIdentical(\(collapse))") { _, _ in }
    }
    
    func setAllowEdit(_ allowEdit: Bool) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("SetAllowEdit(\(allowEdit))") { _, _ in }
    }
    
    func refreshDiffView() {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("RefreshDiffView()") { _, _ in }
    }
}