//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CoreImage.CIFilterBuiltins
import JellyfinAPI
import SwiftUI

/// TV sign-in in the style of Netflix: sign in with a phone through Quick Connect, or with the remote
struct CinemaSignInView<RemoteContent: View>: View {

    enum Method: Hashable {
        case phone
        case remote
    }

    let server: ServerState
    let isQuickConnectEnabled: Bool
    let isLoading: Bool
    let onQuickConnect: (String) async -> Void
    let remoteContent: RemoteContent

    @State
    private var method: Method = .phone

    init(
        server: ServerState,
        isQuickConnectEnabled: Bool,
        isLoading: Bool,
        onQuickConnect: @escaping (String) async -> Void,
        @ViewBuilder remoteContent: () -> RemoteContent
    ) {
        self.server = server
        self.isQuickConnectEnabled = isQuickConnectEnabled
        self.isLoading = isLoading
        self.onQuickConnect = onQuickConnect
        self.remoteContent = remoteContent()
    }

    private var activeMethod: Method {
        isQuickConnectEnabled ? method : .remote
    }

    private var wordmark: some View {
        Text(L10n.swiftfin.uppercased())
            .font(.system(size: 56, weight: .black))
            .tracking(-1)
            .foregroundStyle(CinemaTheme.Colors.accent)
    }

    @ViewBuilder
    private var methodPicker: some View {
        if isQuickConnectEnabled {
            HStack(spacing: 24) {
                Button(L10n.usePhone) {
                    method = .phone
                }
                .isSelected(activeMethod == .phone)

                Button(L10n.useRemote) {
                    method = .remote
                }
                .isSelected(activeMethod == .remote)
            }
            .buttonStyle(.capsule)
            .controlSize(.extraLarge)
            .focusSection()
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                wordmark

                Spacer()

                if isLoading {
                    ProgressView()
                }
            }

            Text(L10n.signInToServer(server.name))
                .font(.largeTitle.weight(.bold))
                .lineLimit(1)
                .padding(.top, 20)

            methodPicker
                .padding(.top, 36)

            Group {
                switch activeMethod {
                case .phone:
                    QuickConnectPanel(server: server, onAuthenticated: onQuickConnect)
                        .transition(.opacity)

                case .remote:
                    remoteContent
                        .frame(maxWidth: 900)
                        .transition(.opacity)
                }
            }
            .padding(.top, 50)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .animation(.easeInOut(duration: 0.25), value: activeMethod)
        .edgePadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .foregroundStyle(CinemaTheme.Colors.primaryText)
        .background(Color.black.ignoresSafeArea())
        .environment(\.colorScheme, .dark)
        .toolbar(.hidden, for: .navigationBar)
    }
}

extension CinemaSignInView {

    /// QR code for the server's Quick Connect page beside the code to enter
    private struct QuickConnectPanel: View {

        let server: ServerState
        let onAuthenticated: (String) async -> Void

        @State
        private var code: String?
        @State
        private var error: Error?

        private var quickConnectURL: URL? {
            let base = server.currentURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return URL(string: base + "/web/#/quickconnect")
        }

        private var qrCode: some View {
            Group {
                if let quickConnectURL, let image = QRCode.image(for: quickConnectURL.absoluteString) {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .padding(24)
                } else {
                    Color.clear
                }
            }
            .frame(width: 380, height: 380)
            .background(Color.white, in: .rect(cornerRadius: 24))
        }

        var body: some View {
            HStack(alignment: .center, spacing: 80) {
                qrCode

                VStack(alignment: .leading, spacing: 28) {
                    Text(L10n.scanWithPhoneCamera)
                        .font(.title2.weight(.bold))

                    Text(L10n.quickConnectPhoneInstruction)
                        .font(.title3)
                        .foregroundStyle(CinemaTheme.Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    if let error {
                        Text(error.localizedDescription)
                            .font(.callout)
                            .foregroundStyle(CinemaTheme.Player.warning)
                    } else if let code {
                        Text(code)
                            .font(.system(size: 88, weight: .bold, design: .rounded))
                            .tracking(18)
                            .monospacedDigit()

                        HStack(spacing: 16) {
                            ProgressView()
                            Text(L10n.waitingForApproval)
                                .font(.callout)
                                .foregroundStyle(CinemaTheme.Colors.tertiaryText)
                        }
                    } else {
                        ProgressView()
                    }
                }
                .frame(maxWidth: 820, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
            .task {
                do {
                    for try await event in server.client.quickConnect.connect() {
                        switch event {
                        case let .polling(code: code):
                            self.code = code
                        case let .authenticated(secret: secret):
                            await onAuthenticated(secret)
                        }
                    }
                } catch {
                    self.error = error
                }
            }
        }
    }
}

private enum QRCode {

    static func image(for string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 12, y: 12)),
              let cgImage = CIContext().createCGImage(output, from: output.extent)
        else { return nil }

        return UIImage(cgImage: cgImage)
    }
}
