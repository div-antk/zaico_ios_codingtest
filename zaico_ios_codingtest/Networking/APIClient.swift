//
//  APIClient.swift
//  zaico_ios_codingtest
//
//  Created by ryo hirota on 2025/03/11.
//

import Foundation

class APIClient {
    static let shared = APIClient()
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private enum InfoKey {
        static let zaicoToken = "ZAICO_API_TOKEN"
    }
    
    private let baseURL = "https://web.zaico.co.jp"
    
    private let token: String = {
        guard let token = Bundle.main.object(forInfoDictionaryKey: InfoKey.zaicoToken) as? String,
              !token.isEmpty else {
            fatalError("ZAICO_API_TOKEN is not set")
        }
        return token
    }()
    
    private init() {}

    private func request<T: Decodable>(
        endpoint: String,
        method: String,
        body: Data?,
        additionalHeaders: [String: String] = [:],
        logPrefix: String
    ) async throws -> T {
        // baseURLとendpointを結合してURLを生成
        guard let url = URL(string: baseURL + endpoint) else {
            throw URLError(.badURL)
        }

        // URLRequestを生成し、HTTPメソッドと共通ヘッダ（Authorization）を設定
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // 呼び出し元から渡された追加ヘッダを設定
        additionalHeaders.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        request.httpBody = body
        
        // 非同期でAPIを実行
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // HTTPステータスコードを検証
        try validateHTTPResponse(response)

        // デバッグ用ログ出力
        if let jsonString = String(data: data, encoding: .utf8) {
            print("[APIClient] \(logPrefix): \(jsonString)")
        }

        return try decoder.decode(T.self, from: data)
    }

    // 2xx以外はAPIエラーとして扱う
    private func validateHTTPResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
    
    func fetchInventories() async throws -> [Inventory] {
        try await request(
            endpoint: "/api/v1/inventories",
            method: "GET",
            body: Optional<Data>.none,
            logPrefix: "API Response"
        )
    }

    func fetchInventory(id: Int?) async throws -> Inventory {
        var endpoint = "/api/v1/inventories"
        if let id {
            endpoint += "/\(id)"
        }

        return try await request(
            endpoint: endpoint,
            method: "GET",
            body: Optional<Data>.none,
            logPrefix: "API Response"
        )
    }

    func createInventory(_ requestModel: CreateInventoryRequest) async throws -> CreateInventoryResponse {
        let body = try encoder.encode(requestModel)

        return try await request(
            endpoint: "/api/v1/inventories",
            method: "POST",
            body: body,
            additionalHeaders: ["Content-Type": "application/json"],
            logPrefix: "Create API Response"
        )
    }
}
