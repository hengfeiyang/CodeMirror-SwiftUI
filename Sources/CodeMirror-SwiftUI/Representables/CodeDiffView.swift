//
//  CodeDiffView.swift
//  
//
//  Created by Claude Code on 8/22/25.
//

import Foundation
import SwiftUI
import WebKit

#if os(OSX)
typealias DiffRepresentableView = NSViewRepresentable
#elseif os(iOS)
typealias DiffRepresentableView = UIViewRepresentable
#endif

// MARK: - CodeDiffView

public struct CodeDiffView: DiffRepresentableView {
    
    @Binding var leftCode: String
    @Binding var rightCode: String
    var theme: CodeViewTheme
    var mode: Mode
    var fontSize: Int
    var showInvisibleCharacters: Bool
    var lineWrapping: Bool
    var readOnly: Bool
    
    var onLoadSuccess: (() -> ())?
    var onLoadFail: ((Error) -> ())?
    var onCoordinatorReady: ((CodeDiffViewController) -> ())?
    
    public init(leftCode: Binding<String>,
                rightCode: Binding<String>,
                mode: Mode = CodeMode.swift.mode(),
                theme: CodeViewTheme = CodeViewTheme.materialPalenight,
                fontSize: Int = 12,
                showInvisibleCharacters: Bool = false,
                lineWrapping: Bool = true,
                readOnly: Bool = false
    ) {
        self._leftCode = leftCode
        self._rightCode = rightCode
        self.mode = mode
        self.theme = theme
        self.fontSize = fontSize      
        self.showInvisibleCharacters = showInvisibleCharacters
        self.lineWrapping = lineWrapping
        self.readOnly = readOnly
    }
    
    // MARK: - Life Cycle
    
    #if os(OSX)
    public func makeNSView(context: Context) -> WKWebView {
        createWebView(context)
    }
    #elseif os(iOS)
    public func makeUIView(context: Context) -> WKWebView {
        createWebView(context)
    }
    #endif
    
    #if os(OSX)
    public func updateNSView(_ webView: WKWebView, context: Context) {
        updateWebView(context)
    }
    #elseif os(iOS)
    public func updateUIView(_ webView: WKWebView, context: Context) {
        updateWebView(context)
    }
    #endif
    
    public func makeCoordinator() -> CodeDiffViewController {
        let coordinator = CodeDiffViewController(self)
        onCoordinatorReady?(coordinator)
        return coordinator
    }
}

// MARK: - Public API

extension CodeDiffView {
    
    public func onLoadSuccess(_ action: @escaping (() -> ())) -> Self {
        var copy = self
        copy.onLoadSuccess = action
        return copy
    }
    
    public func onLoadFail(_ action: @escaping ((Error) -> ())) -> Self {
        var copy = self
        copy.onLoadFail = action
        return copy
    }
    
    public func onCoordinatorReady(_ action: @escaping (CodeDiffViewController) -> Void) -> Self {
        var copy = self
        copy.onCoordinatorReady = action
        return copy
    }
}

// MARK: - Private API

extension CodeDiffView {
    
    private func createWebView(_ context: Context) -> WKWebView {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        let userController = WKUserContentController()
        userController.add(context.coordinator, name: CodeDiffViewRPC.isReady)
        userController.add(context.coordinator, name: CodeDiffViewRPC.textContentDidChange)
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.userContentController = userController
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        #if os(OSX)
        webView.setValue(true, forKey: "drawsTransparentBackground")
        webView.allowsMagnification = false
        #elseif os(iOS)
        webView.isOpaque = false
        #endif
        
        let codeMirrorBundle = try! Bundle.codeMirrorBundle()
        guard let diffHtmlPath = codeMirrorBundle.path(forResource: "diff", ofType: "html") else {
            fatalError("Diff HTML file is missing")
        }
        
        let data = try! Data(contentsOf: URL(fileURLWithPath: diffHtmlPath))
        
        webView.load(data, mimeType: "text/html", characterEncodingName: "utf-8", baseURL: codeMirrorBundle.resourceURL!)
        
        context.coordinator.setWebView(webView)
        context.coordinator.setThemeName(theme.rawValue)
        context.coordinator.setMimeType(mode.mimeType)
        context.coordinator.setFontSize(fontSize)
        context.coordinator.setShowInvisibleCharacters(showInvisibleCharacters)
        context.coordinator.setLineWrapping(lineWrapping)
        context.coordinator.setReadOnly(readOnly)

        // Set content after webView is ready (handled by pending functions)
        context.coordinator.setLeftContent(leftCode)
        context.coordinator.setRightContent(rightCode)
        
        return webView
    }
    
    fileprivate func updateWebView(_ context: CodeDiffView.Context) {
        updateWhatsNecessary(elementGetter: context.coordinator.getMimeType(_:), elementSetter: context.coordinator.setMimeType(_:), currentElementState: self.mode.mimeType)
        
        updateWhatsNecessary(elementGetter: context.coordinator.getLeftContent(_:), elementSetter: context.coordinator.setLeftContent(_:), currentElementState: self.leftCode)
        updateWhatsNecessary(elementGetter: context.coordinator.getRightContent(_:), elementSetter: context.coordinator.setRightContent(_:), currentElementState: self.rightCode)
        
        context.coordinator.setThemeName(self.theme.rawValue)
        context.coordinator.setFontSize(fontSize)
        context.coordinator.setShowInvisibleCharacters(showInvisibleCharacters)
        context.coordinator.setLineWrapping(lineWrapping)
        context.coordinator.setReadOnly(readOnly)
    }
    
    func updateWhatsNecessary(elementGetter: (JavascriptCallback?) -> Void,
                                elementSetter: @escaping (_ elementState: String) -> Void,
                                currentElementState: String) {
        elementGetter({ result in
            switch result {
            case .success(let resp):
                guard let previousElementState = resp as? String else { return }
                
                if previousElementState != currentElementState {
                    elementSetter(currentElementState)
                }
                
                return
            case .failure(let error):
                print("Error \(error)")
                return
            }
        })
    }
}
