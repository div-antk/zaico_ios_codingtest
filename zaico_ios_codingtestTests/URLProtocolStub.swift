//
//  URLProtocolStub.swift
//  zaico_ios_codingtestTests
//
//  Created by Takuya Ando on 2026/02/23.
//

import Foundation

// テスト用のURLProtocolスタブ
final class URLProtocolStub: URLProtocol {

    // テスト側で設定するハンドラ
    // 実際に送信されるURLRequestを受け取り、返却するHTTPレスポンスとDataを定義する
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    // すべてのリクエストをこのスタブで処理対象とする
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    // リクエストの正規化（URLの大文字小文字の統一やヘッダの整理を行う）
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    // URLSessionが開始した際に呼ばれる
    // requestHandlerを実行し、テスト用のレスポンスを返却する
    override func startLoading() {
        guard let handler = Self.requestHandler else {
            fatalError("URLProtocolStub.requestHandler is nil")
        }

        do {
            // 実際に送られようとした request を受け取ってテスト用のレスポンスを返す
            let (response, data) = try handler(request)
            // URLSessionに「レスポンス受信」「データ受信」「完了」を伝える
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    // 読み込み停止時の処理
    override func stopLoading() {}
}
