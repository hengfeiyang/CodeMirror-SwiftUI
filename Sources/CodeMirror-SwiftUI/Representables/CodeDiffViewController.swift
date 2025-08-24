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

// MARK: - JavascriptFunction

private struct JavascriptFunction {
  
  let functionString: String
  let callback: ((Result<Any?, Error>) -> Void)?
  
  init(functionString: String, callback: ((Result<Any?, Error>) -> Void)? = nil) {
    self.functionString = functionString
    self.callback = callback
  }
}

public class CodeDiffViewController: NSObject {
    
    var parent: CodeDiffView
    var webView: WKWebView?

    fileprivate var pageLoaded = false
    fileprivate var pendingFunctions = [JavascriptFunction]()
  
    init(_ parent: CodeDiffView) {
        self.parent = parent
    }
    
    // MARK: - Pending Functions Management
    
    private func addFunction(function: JavascriptFunction) {
        pendingFunctions.append(function)
    }
    
    private func callJavascriptFunction(function: JavascriptFunction) {
        webView?.evaluateJavaScript(function.functionString) { (response, error) in
            if let error = error {
                function.callback?(.failure(error))
            }
            else {
                function.callback?(.success(response))
            }
        }
    }
    
    private func callPendingFunctions() {
        for function in pendingFunctions {
            callJavascriptFunction(function: function)
        }
        pendingFunctions.removeAll()
    }
    
    private func callJavascript(javascriptString: String, callback: ((Result<Any?, Error>) -> Void)? = nil) {
        if pageLoaded {
            callJavascriptFunction(function: JavascriptFunction(functionString: javascriptString, callback: callback))
        }
        else {
            addFunction(function: JavascriptFunction(functionString: javascriptString, callback: callback))
        }
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
            pageLoaded = true
            callPendingFunctions()
            print("CodeDiffViewController: isReady")
            break
        case CodeDiffViewRPC.textContentDidChange:
            let content = (message.body as? [String: Any]) ?? [:]
            print("CodeDiffViewController: textContentDidChange: \(content)")
            if let leftContent = content["left"] as? String, leftContent != parent.leftContent {
                parent.onContentChange?(leftContent)
                parent.leftContent = leftContent
            }
            if let rightContent = content["right"] as? String, rightContent != parent.rightContent {
                parent.onContentChange?(rightContent)
                parent.rightContent = rightContent
            }
            break
        default:
            break
        }
    }
}

// MARK: - JavaScript Interface

extension CodeDiffViewController {

    public func setWebView(_ webView: WKWebView) {
        self.webView = webView
        setDefaultTheme()
        setTabInsertsSpaces(true)
    }

    func setTabInsertsSpaces(_ value: Bool) {
        callJavascript(javascriptString: "SetTabInsertSpaces(\(value));")
    }
    
    func setMimeType(_ mimeType: String) {
        callJavascript(javascriptString: "SetMimeType('\(mimeType)')")
    }
    
    public func getMimeType(_ block: JavascriptCallback?) {
        callJavascript(javascriptString: "GetMimeType()", callback: block)
    }
    
    func setLeftContent(_ value: String) {
        print("CodeDiffViewController: setLeftContent called with value: \(value)")
        if let hexString = value.data(using: .utf8)?.hexEncodedString() {
            let script = """
            var content = "\(hexString)"; SetLeftContent(content);
            """
            callJavascript(javascriptString: script)
        }
    }
    
    func setRightContent(_ value: String) {
        print("CodeDiffViewController: setRightContent called with value: \(value)")
        if let hexString = value.data(using: .utf8)?.hexEncodedString() {
            let script = """
            var content = "\(hexString)"; SetRightContent(content);
            """
            callJavascript(javascriptString: script)
        }
    }
    
    func setFontSize(_ fontSize: Int) {
        callJavascript(javascriptString: "SetFontSize(\(fontSize))")
    }
    
    // MARK: - Additional API functions for consistency with regular CodeView
    
    public func getSupportedMimeTypes(completion: @escaping (String) -> Void) {
        callJavascript(javascriptString: "SupportedMimeTypes()") { result in
            switch result {
            case .success(let response):
                if let mimeTypes = response as? String {
                    completion(mimeTypes)
                }
            case .failure(_):
                completion("")
            }
        }
    }
    
    func setLineWrapping(_ wrapping: Bool) {
        callJavascript(javascriptString: "SetLineWrapping(\(wrapping))")
    }
    
    func getLineWrapping(completion: @escaping (Bool) -> Void) {
        callJavascript(javascriptString: "GetLineWrapping()") { result in
            switch result {
            case .success(let response):
                if let wrapping = response as? Bool {
                    completion(wrapping)
                }
            case .failure(_):
                completion(false)
            }
        }
    }
    
    func setReadOnly(_ readOnly: Bool) {
        callJavascript(javascriptString: "SetReadOnly(\(readOnly))")
    }
    
    func getReadOnly(completion: @escaping (Bool) -> Void) {
        callJavascript(javascriptString: "GetReadOnly()") { result in
            switch result {
            case .success(let response):
                if let readOnly = response as? Bool {
                    completion(readOnly)
                }
            case .failure(_):
                completion(false)
            }
        }
    }
    
    func setIndentUnit(_ unit: Int) {
        callJavascript(javascriptString: "SetIndentUnit(\(unit))")
    }
    
    func getIndentUnit(completion: @escaping (Int) -> Void) {
        callJavascript(javascriptString: "GetIndentUnit()") { result in
            switch result {
            case .success(let response):
                if let unit = response as? Int {
                    completion(unit)
                }
            case .failure(_):
                completion(2)
            }
        }
    }
    
    func setThemeName(_ theme: String) {
        callJavascript(javascriptString: "SetTheme('\(theme)')")
    }
    
    func setShowInvisibleCharacters(_ show: Bool) {
        callJavascript(javascriptString: "ToggleInvisible(\(show))")
    }
    
    func toggleInvisible(_ toggle: Bool) {
        callJavascript(javascriptString: "ToggleInvisible(\(toggle))")
    }
    
    func setTabSize(_ size: Int) {
        callJavascript(javascriptString: "SetTabSize(\(size))")
    }
    
    func getTabSize(completion: @escaping (Int) -> Void) {
        callJavascript(javascriptString: "GetTabSize()") { result in
            switch result {
            case .success(let response):
                if let size = response as? Int {
                    completion(size)
                }
            case .failure(_):
                completion(4)
            }
        }
    }
    
    func setTabInsertSpaces(_ flag: Bool) {
        callJavascript(javascriptString: "SetTabInsertSpaces(\(flag))")
    }
    
    func getTabInsertSpaces(completion: @escaping (Bool) -> Void) {
        callJavascript(javascriptString: "GetTabInsertSpaces()") { result in
            switch result {
            case .success(let response):
                if let flag = response as? Bool {
                    completion(flag)
                }
            case .failure(_):
                completion(true)
            }
        }
    }
    
    public func clearHistory() {
        callJavascript(javascriptString: "ClearHistory()")
    }
    
    public func isClean(completion: @escaping (Bool) -> Void) {
        callJavascript(javascriptString: "IsClean()") { result in
            switch result {
            case .success(let response):
                if let clean = response as? Bool {
                    completion(clean)
                }
            case .failure(_):
                completion(true)
            }
        }
    }
    
    func getTextSelection(completion: @escaping (String) -> Void) {
        callJavascript(javascriptString: "GetTextSelection()") { result in
            switch result {
            case .success(let response):
                if let selection = response as? String {
                    completion(selection)
                }
            case .failure(_):
                completion("")
            }
        }
    }    
    
    // MARK: - Copy functionality for diff view
    
    public func getLeftContent(_ block: JavascriptCallback?) {
        callJavascript(javascriptString: "GetLeftContent()", callback: block)
    }
    
    public func getRightContent(_ block: JavascriptCallback?) {
        callJavascript(javascriptString: "GetRightContent()", callback: block)
    }
    
    // Convenience methods for string callbacks (used by demo)
    public func getLeftContent(completion: @escaping (String) -> Void) {
        callJavascript(javascriptString: "GetLeftContent()") { result in
            switch result {
            case .success(let response):
                if let content = response as? String {
                    completion(content)
                } else {
                    completion("")
                }
            case .failure(_):
                completion("")
            }
        }
    }
    
    public func getRightContent(completion: @escaping (String) -> Void) {
        callJavascript(javascriptString: "GetRightContent()") { result in
            switch result {
            case .success(let response):
                if let content = response as? String {
                    completion(content)
                } else {
                    completion("")
                }
            case .failure(_):
                completion("")
            }
        }
    }

    func setDefaultTheme() {
        setMimeType("application/json")
    }
}
