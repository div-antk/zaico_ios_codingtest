//
//  CreateInventoryTests.swift
//  zaico_ios_codingtest
//
//  Created by Takuya Ando on 2026/02/23.
//

import XCTest
@testable import zaico_ios_codingtest

final class CreateInventoryTests: XCTestCase {

    // 正常系：POST・Body・レスポンスdecodeを検証する
    func test_createInventory_sendsPOST_and_decodesResponse() async throws {
        // ------------------------------------------------------------
        // Arrange（準備）
        // ------------------------------------------------------------
        let session = makeStubbedSession()
        let client = APIClient(session: session)

        URLProtocolStub.requestHandler = { request in
            // --------------------------------------------------------
            // Assert（リクエスト検証）
            // --------------------------------------------------------
            // 期待したHTTPメソッドで送られているか
            XCTAssertEqual(request.httpMethod, "POST")
            
            // 期待したエンドポイント（パス）に送られているか
            XCTAssertEqual(request.url?.path, "/api/v1/inventories")
            
            // POSTのJSON送信なのでContent-Typeが適切に指定されているか
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

            // URLRequestのBody（httpBody / httpBodyStream）をDataとして取得する
            let body = try self.requestBodyData(from: request)
            
            // JSONとしてパースし、titleが正しく入っているかを確認
            let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
            XCTAssertEqual(json?["title"] as? String, "test title")

            // --------------------------------------------------------
            // スタブレスポンス（擬似的なサーバーレスポンス）
            // --------------------------------------------------------
            // APIドキュメントに近い形のJSONを返して、デコードできるかを確認する
            let responseJSON = """
            {"code":200,"status":"success","message":"ok","data_id":123}
            """.data(using: .utf8)!

            // ステータスコード200のHTTPレスポンスを組み立てる
            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!

            // URLProtocolStubへ「このレスポンスを返す」と伝える
            return (response, responseJSON)
        }

        // ------------------------------------------------------------
        // Act（実行）
        // ------------------------------------------------------------
        // createInventoryを呼ぶと、上のrequestHandlerが呼ばれ、スタブレスポンスが返る
        let res = try await client.createInventory(CreateInventoryRequest(title: "test title"))

        // ------------------------------------------------------------
        // Assert（結果検証）
        // ------------------------------------------------------------
        // レスポンスJSONがCreateInventoryResponseに正しくデコードされているか
        XCTAssertEqual(res.code, 200)
        // "data_id" → dataId のマッピング（CodingKeys）が効いているか
        XCTAssertEqual(res.dataId, 123)
    }
    
    // 異常系：2xx以外でエラーになることを検証する
    func test_createInventory_whenStatusCodeIsNot2xx_throwsError() async {
        // ------------------------------------------------------------
        // Arrange（準備）
        // ------------------------------------------------------------
        let session = makeStubbedSession()
        let client = APIClient(session: session)

        URLProtocolStub.requestHandler = { request in
            // --------------------------------------------------------
            // Assert（リクエスト前提の確認）
            // --------------------------------------------------------
            // 異常系テストだが、正しいエンドポイントに送信しようとしていることは確認する
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/api/v1/inventories")

            // --------------------------------------------------------
            // スタブレスポンス（異常系）
            // --------------------------------------------------------
            // 2xx 以外のステータスコードを返すことで、validateHTTPResponse がエラーをthrowするか検証する
            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!

            // エラーケースのため、レスポンスボディは空でOK
            let data = Data()

            return (response, data)
        }
        // ------------------------------------------------------------
        // Act（実行） & Assert（結果検証）
        // ------------------------------------------------------------
        do {
            _ = try await client.createInventory(CreateInventoryRequest(title: "test title"))
            XCTFail("Expected to throw, but it succeeded.")
        } catch {
            // validateHTTPResponse で 2xx以外は URLError(.badServerResponse) にまとめている
            let urlError = error as? URLError
            XCTAssertEqual(urlError?.code, .badServerResponse)
        }
    }
    
    // ヘッダ：Authorizationが付与されることを検証する
    func test_createInventory_setsAuthorizationHeader() async throws {
        // ------------------------------------------------------------
        // Arrange（準備）
        // ------------------------------------------------------------
        let session = makeStubbedSession()
        let client = APIClient(session: session)

        URLProtocolStub.requestHandler = { request in
            // --------------------------------------------------------
            // Assert（Authorizationヘッダが付いているか）
            // --------------------------------------------------------
            let auth = request.value(forHTTPHeaderField: "Authorization")
            XCTAssertNotNil(auth)
            XCTAssertTrue(auth?.hasPrefix("Bearer ") == true)

            // tokenが一致するか確認（漏洩しないようprintはしない）
            if let token = Bundle.main.object(forInfoDictionaryKey: "ZAICO_API_TOKEN") as? String,
               !token.isEmpty {
                XCTAssertEqual(auth, "Bearer \(token)")
            }

            // --------------------------------------------------------
            // スタブレスポンス（擬似的なサーバーレスポンス）
            // --------------------------------------------------------
            let responseJSON = """
            {"code":200,"status":"success","message":"ok","data_id":123}
            """.data(using: .utf8)!

            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!

            return (response, responseJSON)
        }

        // ------------------------------------------------------------
        // Act（実行）
        // ------------------------------------------------------------
        _ = try await client.createInventory(CreateInventoryRequest(title: "test title"))

        // Assert は requestHandler 内で実施しているのでここでは不要
    }

    // 通信をスタブできるURLSessionを作る
    private func makeStubbedSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: config)
    }
    
    // URLRequestのBodyをDataとして取り出す
    private func requestBodyData(from request: URLRequest) throws -> Data {
        // URLSessionの内部実装により、httpBody が httpBodyStream に変換されることがある
        // そのためどちらでも検証できるようにヘルパーでDataとして取り出す
        if let body = request.httpBody {
            return body
        }
        if let stream = request.httpBodyStream {
            return try readAll(from: stream)
        }
        throw NSError(
            domain: "Test",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "Request body is nil"]
        )
    }

    // InputStreamを最後まで読み込み、Dataとして取得するユーティリティ
    private func readAll(from stream: InputStream) throws -> Data {
        // ストリームを読み込み可能な状態にする
        stream.open()
        
        // 関数終了時に必ずストリームを閉じる（正常終了・エラー問わず）
        defer { stream.close() }
        
        // 読み込んだデータを蓄積するためのバッファ
        var data = Data()
        
        // 1回あたりに読み込むバイト数（適当な固定サイズ）
        let bufferSize = 1024
        var buffer = [UInt8](repeating: 0, count: bufferSize)

        // ストリームにデータが残っている限り繰り返す
        while stream.hasBytesAvailable {

            // 最大 bufferSize バイト読み込む
            let read = stream.read(&buffer, maxLength: bufferSize)

            // 読み込みエラー（負の値が返る）
            if read < 0 {
                throw stream.streamError ?? NSError(domain: "Test", code: 1)
            }
            // 0バイトなら読み込み終了
            if read == 0 { break }

            // 読み込んだ分だけ Data に追加
            data.append(buffer, count: read)
        }
        return data
    }
}
